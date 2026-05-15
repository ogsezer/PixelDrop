// AppCommands.swift
// PixelDrop
//
// Custom menu commands injected into the macOS menu bar.
// Adds:  File > Open Image…
//        File > Open Recent  (submenu)
//        File > Clear Recents

import SwiftUI
import ImageViewerKit

struct AppCommands: Commands {

    @ObservedObject var recentFiles: RecentFilesManager

    var body: some Commands {
        // Replace the default "New" command group with our File menu items
        CommandGroup(replacing: .newItem) {

            // ── File > Open Image… ────────────────────────────────────────
            Button("Open Image…") {
                presentOpenPanel()
            }
            .keyboardShortcut("o", modifiers: .command)

            // ── File > Open Recent ────────────────────────────────────────
            Menu("Open Recent") {
                if recentFiles.urls.isEmpty {
                    Text("No Recent Images")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentFiles.urls.prefix(10), id: \.self) { url in
                        Button(url.lastPathComponent) {
                            openURL(url)
                        }
                    }
                    Divider()
                    Button("Clear Menu") {
                        recentFiles.clear()
                    }
                }
            }

            Divider()
        }
    }

    // MARK: - Helpers

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.title                   = "Open Images"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories    = true
        panel.canChooseFiles          = true

        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
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

    private func openURL(_ url: URL) {
        recentFiles.add(urls: [url])
        var config = ImageViewerConfiguration()
        config.allowsHDR = true
        ImageViewer.open(url: url, configuration: config)
    }
}
