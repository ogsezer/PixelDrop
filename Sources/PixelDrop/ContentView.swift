// ContentView.swift
// PixelDrop
//
// Root view of the app window.
// Shows either the DropZoneView (no recents) or RecentGridView (has recents).
// Handles drag-and-drop at the window level.

import SwiftUI
import UniformTypeIdentifiers
import ImageViewerKit

struct ContentView: View {

    @EnvironmentObject var recentFiles: RecentFilesManager
    @State private var isDragging = false

    // All image UTTypes the app accepts
    private let acceptedTypes: [UTType] = [
        .image, .rawImage, .jpeg, .png, .tiff, .gif, .bmp,
        .heic, .webP,
        UTType("public.avif")     ?? .image,
        UTType("public.exr")      ?? .image,
        UTType("com.adobe.raw-image") ?? .rawImage
    ]

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────────
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            // ── Main content ─────────────────────────────────────────────────
            if recentFiles.urls.isEmpty {
                DropZoneView(isDragging: isDragging) {
                    presentOpenPanel()
                }
            } else {
                RecentGridView(onOpenMore: presentOpenPanel)
            }

            // ── Drag highlight overlay ───────────────────────────────────────
            if isDragging {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .background(
                        Color.accentColor.opacity(0.08)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                    .padding(8)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        // Window-level drop target
        .onDrop(of: acceptedTypes, isTargeted: $isDragging, perform: handleDrop)
        .toolbar { toolbarItems }
        .navigationTitle("PixelDrop")
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack(spacing: 6) {
                Image(systemName: "photo.stack")
                    .foregroundStyle(Color.accentColor)   // `.accent` ShapeStyle unavailable on macOS 13
                Text("PixelDrop")
                    .fontWeight(.semibold)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                presentOpenPanel()
            } label: {
                Label("Open Image…", systemImage: "folder.badge.plus")
            }
            .keyboardShortcut("o", modifiers: .command)
        }
        if !recentFiles.urls.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    recentFiles.clear()
                } label: {
                    Label("Clear Recents", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Open Panel

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.title                    = "Open Images"
        panel.allowsMultipleSelection  = true
        panel.canChooseDirectories     = true
        panel.canChooseFiles           = true
        panel.allowedContentTypes      = acceptedTypes

        guard panel.runModal() == .OK else { return }
        open(urls: expandDirectories(panel.urls))
    }

    // MARK: - Drop Handler

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Use structured concurrency — avoids mutating a captured var
        // across concurrently-executing completion handlers.
        Task { @MainActor in
            var collected: [URL] = []
            await withTaskGroup(of: URL?.self) { group in
                for provider in providers {
                    group.addTask { await provider.pixelDropFileURL() }
                }
                for await url in group {
                    if let url { collected.append(url) }
                }
            }
            let expanded = expandDirectories(collected)
            if !expanded.isEmpty { open(urls: expanded) }
        }
        return true
    }

    // MARK: - Open Logic

    private func open(urls: [URL]) {
        guard !urls.isEmpty else { return }
        recentFiles.add(urls: urls)

        var config = ImageViewerConfiguration()
        config.allowsHDR           = true
        config.showsThumbnailStrip = urls.count > 1

        if urls.count == 1 {
            ImageViewer.open(url: urls[0], configuration: config)
        } else {
            ImageViewer.open(urls: urls, startingAt: 0, configuration: config)
        }
    }

    // MARK: - Helpers

    /// Expand any dropped folder into its image files (one level deep).
    private func expandDirectories(_ urls: [URL]) -> [URL] {
        var result: [URL] = []
        let imageExts = Set(["jpg","jpeg","png","heic","heif","avif","webp",
                             "tiff","tif","gif","bmp","exr","cr2","cr3",
                             "nef","arw","dng","raf","orf","rw2"])
        for url in urls {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if isDir.boolValue {
                let contents = (try? FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: .skipsHiddenFiles
                )) ?? []
                result += contents
                    .filter { imageExts.contains($0.pathExtension.lowercased()) }
                    .sorted { $0.lastPathComponent < $1.lastPathComponent }
            } else {
                result.append(url)
            }
        }
        return result
    }
}

// MARK: - NSItemProvider async helper

private extension NSItemProvider {
    /// Async wrapper around loadItem — safely bridges the callback into Swift concurrency.
    /// Namespaced to `pixelDropFileURL` to avoid conflicts with other extensions.
    func pixelDropFileURL() async -> URL? {
        await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UniformTypeIdentifiers.UTType.fileURL.identifier) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
