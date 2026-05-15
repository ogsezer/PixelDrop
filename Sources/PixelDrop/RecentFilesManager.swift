// RecentFilesManager.swift
// PixelDrop
//
// Persists recently opened image URLs to UserDefaults.
// Published so SwiftUI views update automatically.

import SwiftUI
import Combine

final class RecentFilesManager: ObservableObject {

    // MARK: - Published State

    /// Most-recently-opened URLs, newest first. Max 30 entries.
    @Published private(set) var urls: [URL] = []

    // MARK: - Constants

    private let key        = "PixelDrop.RecentURLs"
    private let maxEntries = 30

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - Public API

    /// Add one or more URLs to the top of the recents list.
    func add(urls newURLs: [URL]) {
        var combined = newURLs + urls
        // Deduplicate — keep first occurrence (newest)
        var seen = Set<URL>()
        combined = combined.filter { seen.insert($0).inserted }
        urls = Array(combined.prefix(maxEntries))
        persist()
    }

    /// Remove a single URL from the list.
    func remove(url: URL) {
        urls.removeAll { $0 == url }
        persist()
    }

    /// Wipe the entire recents list.
    func clear() {
        urls = []
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        let paths = urls.map(\.path)
        UserDefaults.standard.set(paths, forKey: key)
    }

    private func load() {
        let paths = UserDefaults.standard.stringArray(forKey: key) ?? []
        // Filter out URLs whose files no longer exist on disk
        urls = paths
            .map { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
