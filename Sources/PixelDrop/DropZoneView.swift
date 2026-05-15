// DropZoneView.swift
// PixelDrop
//
// The welcome screen shown when no recent files exist.
// Features an animated dashed border, file type badges, and an open button.

import SwiftUI

struct DropZoneView: View {

    let isDragging: Bool
    let onOpen: () -> Void

    @State private var dashPhase: CGFloat = 0
    @State private var glowPulse: Bool = false

    // Supported format badges shown at the bottom
    private let formats = ["HEIC","HDR","EXR","RAW","AVIF","WebP","JPEG","PNG","TIFF","GIF","BMP"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // ── Drop Zone Card ───────────────────────────────────────────────
            VStack(spacing: 28) {

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(isDragging ? 0.18 : 0.10))
                        .frame(width: 120, height: 120)
                        .scaleEffect(glowPulse ? 1.06 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                            value: glowPulse
                        )

                    Image(systemName: isDragging ? "photo.fill.on.rectangle.fill" : "photo.on.rectangle")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Color.accentColor)
                        // .symbolEffect(.bounce) requires macOS 14+ — use scaleEffect spring instead
                        .scaleEffect(isDragging ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: isDragging)
                }

                // Text
                VStack(spacing: 8) {
                    Text(isDragging ? "Release to Open" : "Drop Images Here")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: isDragging)

                    Text("or open a file, folder, or RAW image")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Open Button
                Button(action: onOpen) {
                    Label("Open Image…", systemImage: "folder.badge.plus")
                        .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("o", modifiers: .command)
            }
            .padding(48)
            .background {
                // Animated dashed border
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: [8, 6],
                            dashPhase: dashPhase
                        )
                    )
                    .foregroundStyle(
                        isDragging ? Color.accentColor : Color.secondary.opacity(0.4)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
            }
            .padding(.horizontal, 60)

            Spacer()

            // ── Format Badge Strip ───────────────────────────────────────────
            VStack(spacing: 12) {
                Text("Supports all major formats")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(formats, id: \.self) { fmt in
                            Text(fmt)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.12))
                                )
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            glowPulse = true
            // Animate dash phase for marching-ants effect
            withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
                dashPhase = -14
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DropZoneView(isDragging: false, onOpen: {})
        .frame(width: 700, height: 500)
}
