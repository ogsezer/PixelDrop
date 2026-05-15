// RecentGridView.swift
// PixelDrop
//
// A responsive LazyVGrid of recently opened images.
// Each card shows a quick-look thumbnail, filename, format badge,
// and a hover-reveal remove button.

import SwiftUI
import ImageViewerKit

struct RecentGridView: View {

    @EnvironmentObject var recentFiles: RecentFilesManager
    let onOpenMore: () -> Void

    // Adaptive columns — min 160 pt wide each
    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ───────────────────────────────────────────────────────
            HStack {
                Text("Recent Images")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(recentFiles.urls.count) file\(recentFiles.urls.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // ── Grid ─────────────────────────────────────────────────────────
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(recentFiles.urls, id: \.self) { url in
                        ImageCard(url: url) {
                            openSingle(url: url)
                        } onRemove: {
                            withAnimation(.spring(duration: 0.3)) {
                                recentFiles.remove(url: url)
                            }
                        }
                    }
                }
                .padding(24)
                .animation(.spring(duration: 0.35), value: recentFiles.urls)
            }

            Divider()

            // ── Footer ───────────────────────────────────────────────────────
            HStack(spacing: 12) {
                Button(action: openAll) {
                    Label("Open All as Gallery", systemImage: "rectangle.grid.3x2")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: onOpenMore) {
                    Label("Open More…", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func openSingle(url: URL) {
        recentFiles.add(urls: [url])    // bump to top
        var config = ImageViewerConfiguration()
        config.allowsHDR = true
        config.showsThumbnailStrip = true

        // Open in gallery mode with all recents so user can swipe through
        let all = recentFiles.urls
        let idx = all.firstIndex(of: url) ?? 0
        ImageViewer.open(urls: all, startingAt: idx, configuration: config)
    }

    private func openAll() {
        guard !recentFiles.urls.isEmpty else { return }
        var config = ImageViewerConfiguration()
        config.allowsHDR = true
        config.showsThumbnailStrip = true
        ImageViewer.open(urls: recentFiles.urls, startingAt: 0, configuration: config)
    }
}

// MARK: - ImageCard

private struct ImageCard: View {

    let url: URL
    let onOpen: () -> Void
    let onRemove: () -> Void

    @State private var thumbnail: NSImage? = nil
    @State private var isHovered = false

    private var formatBadge: String { url.pathExtension.uppercased() }

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 0) {

                // ── Thumbnail ────────────────────────────────────────────────
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let thumb = thumbnail {
                            Image(nsImage: thumb)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.12))
                                .overlay(
                                    ProgressView()
                                        .controlSize(.small)
                                )
                        }
                    }
                    .frame(height: 140)
                    .clipped()
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: 10,
                        topTrailingRadius: 10
                    ))

                    // Format badge
                    Text(formatBadge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                        .padding(8)

                    // Remove button (hover-reveal)
                    if isHovered {
                        Button {
                            onRemove()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white, Color.black.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .padding(6)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // ── Filename ─────────────────────────────────────────────────
                HStack {
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(UnevenRoundedRectangle(
                    bottomLeadingRadius: 10,
                    bottomTrailingRadius: 10
                ))
            }
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(isHovered ? 0.18 : 0.08),
                        radius: isHovered ? 8 : 3,
                        y: isHovered ? 4 : 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(duration: 0.25), value: isHovered)
        .onHover { isHovered = $0 }
        .task { await loadThumbnail() }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail() async {
        thumbnail = await ThumbnailCache.shared.thumbnail(for: url)
    }
}
