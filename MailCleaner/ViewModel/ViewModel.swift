//
//  ViewModel.swift
//  MailCleaner
//
//  Created by mlnlsTER on 06.11.2025.
//

import Foundation
import AppKit
import Combine
import os

@MainActor
final class MailCleanerViewModel: ObservableObject {

    @Published var cacheFolders: [CacheFolderInfo] = []
    @Published var totalSize: Int64 = 0
    @Published var isProcessing: Bool = false
    @Published var fullDiskAccessRequired: Bool = false
    @Published var emptyCache: Bool = true

    let dependencies: MailCleanerDependencies

    init(dependencies: MailCleanerDependencies) {
        self.dependencies = dependencies
    }

    func requestMailFolderAccess() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select Mail folder"
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(bookmark, forKey: "MailFolderURLBookmark")
                return url
            } catch {
                Log.access.error("Failed to create bookmark: \(error.localizedDescription)")
            }
        }
        return nil
    }

    // Returns URL for Mail folder and whether access has been started (if needed)
    func mailFolderURLForAccess() -> (url: URL, needsStop: Bool)? {
        switch dependencies.mode {
        case .appstore:
            var mailURL: URL?
            if let data = UserDefaults.standard.value(forKey: "MailFolderURLBookmark") as? Data {
                var isStale = false
                do {
                    mailURL = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                    if isStale {
                        mailURL = requestMailFolderAccess()
                    }
                } catch {
                    Log.access.warning("Failed to resolve bookmark: \(error.localizedDescription)")
                    mailURL = requestMailFolderAccess()
                }
            } else {
                mailURL = requestMailFolderAccess()
            }
            guard let url = mailURL else { return nil }
            guard url.startAccessingSecurityScopedResource() else {
                Log.access.critical("Failed to start access to \(url.path)")
                return nil
            }
            return (url, true)
        case .public:
            guard let url = dependencies.baseURL else { return nil }
            return (url, false)
        }
    }

    func scan() async {
        emptyCache = true
        isProcessing = true
        defer { isProcessing = false }
        var folders: [CacheFolderInfo] = []

        guard let (url, needsStop) = mailFolderURLForAccess() else {
            Log.access.critical("Access denied")
            fullDiskAccessRequired = true
            cacheFolders = []
            totalSize = 0
            return
        }
        defer {
            if needsStop {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            folders = try await dependencies.scanner.scan(baseURL: url)
        } catch {
            Log.scanner.error("Scan failed: \(error.localizedDescription)")
            fullDiskAccessRequired = true
        }
        guard !folders.isEmpty else {
            cacheFolders = []
            totalSize = 0
            return
        }
        emptyCache = false
        cacheFolders = folders
        totalSize = folders.reduce(0) { $0 + $1.size }
        Log.scanner.info("Folders: \(self.cacheFolders)")
    }

    func clear(deletePermanently: Bool) async {
        isProcessing = true
        defer { isProcessing = false }
        let urls = cacheFolders.map { $0.url }

        guard let (url, needsStop) = mailFolderURLForAccess() else {
            Log.access.critical("Access denied for clear()")
            fullDiskAccessRequired = true
            return
        }
        defer {
            if needsStop {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            if deletePermanently {
                try await dependencies.deleter.deletePermanently(urls: urls)
            } else {
                try await dependencies.deleter.moveToTrash(urls: urls)
            }
            cacheFolders.removeAll()
            totalSize = 0
        } catch {
            if let mailError = error as? MailCacheDeleter.Error {
                switch mailError {
                case .outsideBasePath(let url):
                    Log.deleter.error("Clear error: outsideBasePath: \(url.path)")
                case .deletionFailed(let url, let underlying):
                    Log.deleter.error("Clear error: deletionFailed: \(url.path), underlying: \(underlying)")
                case .trashFailed(let url, let underlying):
                    Log.deleter.error("Clear error: trashFailed: \(url.path), underlying: \(underlying)")
                }
            } else {
                Log.deleter.critical("Clear error (unknown): \(error.localizedDescription)")
            }
        }
    }
}
