// PixelDropApp.swift
// PixelDrop
//
// App entry point. Wires up the scene, environment objects, and menu commands.

import SwiftUI
import AppKit
import ImageViewerKit

@main
struct PixelDropApp: App {

    @StateObject private var recentFiles = RecentFilesManager()

    init() {
        // SPM-built executables have no Info.plist, so macOS treats them as
        // background processes by default — no Dock icon, no menu bar, no
        // visible window. Force foreground activation so the app appears
        // properly when launched via `swift run` or directly from a binary.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recentFiles)
                .frame(minWidth: 640, minHeight: 480)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(recentFiles: recentFiles)
        }
    }
}
