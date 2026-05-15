// PixelDropApp.swift
// PixelDrop
//
// App entry point. Wires up the scene, environment objects, and menu commands.

import SwiftUI
import ImageViewerKit

@main
struct PixelDropApp: App {

    @StateObject private var recentFiles = RecentFilesManager()

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
