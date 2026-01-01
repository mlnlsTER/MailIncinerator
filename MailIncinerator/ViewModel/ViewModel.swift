//
//  ViewModel.swift
//  MailIncinerator
//
//  Created by mlnlsTER on 06.11.2025.
//

import Foundation
import AppKit
import Combine
import os

private func isMailRunning() -> Bool {
    !NSRunningApplication.runningApplications(withBundleIdentifier: CacheConstants.mailBundleIdentifier).isEmpty
}

@MainActor
class MailIncineratorViewModel: ObservableObject {

    @Published var cacheFolders: [CacheFolderInfo] = []
    @Published var totalSize: Int64 = 0
    @Published var isProcessing: Bool = false
    @Published var fullDiskAccessRequired: Bool = false
    @Published var emptyCache: Bool = true
    
    @Published var statusMessage: String?
    @Published var lastOperationResult: OperationResult?

    enum OperationResult {
        case success(message: String)
        case empty
        case failure(message: String)
    }

    let dependencies: MailCleanerDependencies

    init(dependencies: MailCleanerDependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Helper

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Methods

    func requireMailClosed() -> Bool {
        guard !isMailRunning() else {
            let alert = NSAlert()
            alert.messageText = CacheConstants.mailRunning
            alert.informativeText = CacheConstants.mailRunningBlockingMessage
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Retry")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            return response == .alertFirstButtonReturn && !isMailRunning()
        }
        return true
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
                lastOperationResult = .failure(message: "Failed to create bookmark: \(error.localizedDescription)")
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
                    lastOperationResult = .failure(message: "Failed to resolve folder access: \(error.localizedDescription)")
                    mailURL = requestMailFolderAccess()
                }
            } else {
                mailURL = requestMailFolderAccess()
            }
            guard let url = mailURL else { return nil }
            guard url.startAccessingSecurityScopedResource() else {
                Log.access.critical("Failed to start access to \(url.path)")
                lastOperationResult = .failure(message: "Failed to access folder at path: \(url.path)")
                return nil
            }
            return (url, true)
        case .public:
            guard let url = dependencies.baseURL else { return nil }
            return (url, false)
        }
    }

    // Checks whether the app currently has access to the Mail folder.
    //
    // For `.appstore` mode, it attempts to resolve the stored security-scoped bookmark or
    // checks access without prompting the user to select a folder.
    // For `.public` mode, it verifies that the baseURL exists and is accessible.
    // Sets `fullDiskAccessRequired` accordingly without performing any scanning or folder enumeration.
    public func checkMailFolderAccess() async {
        switch dependencies.mode {
        case .appstore:
            if let data = UserDefaults.standard.value(forKey: "MailFolderURLBookmark") as? Data {
                var isStale = false
                do {
                    let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                    if isStale {
                        fullDiskAccessRequired = true
                    } else {
                        if url.startAccessingSecurityScopedResource() {
                            fullDiskAccessRequired = false
                            url.stopAccessingSecurityScopedResource()
                        } else {
                            fullDiskAccessRequired = true
                        }
                    }
                } catch {
                    fullDiskAccessRequired = true
                }
            } else {
                fullDiskAccessRequired = true
            }
        case .public:
            if let url = dependencies.baseURL {
                var isReachable = false
                do {
                    let fileManager = FileManager.default
                    let _ = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    isReachable = true
                } catch {
                    isReachable = false
                }
                fullDiskAccessRequired = !isReachable
            } else {
                fullDiskAccessRequired = true
            }
        }
    }

    func scan() async {
        guard requireMailClosed() else {
            Log.access.info("Scan cancelled: Mail is running")
            return
        }
        emptyCache = true
        isProcessing = true
        defer { isProcessing = false }
        var folders: [CacheFolderInfo] = []

        guard let (url, needsStop) = mailFolderURLForAccess() else {
            Log.access.critical("Access denied")
            fullDiskAccessRequired = true
            cacheFolders = []
            totalSize = 0
            lastOperationResult = .failure(message: "Access denied to Mail folder. Full Disk Access may be required.")
            return
        }
        defer {
            if needsStop {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            folders = try await dependencies.scanner.scan(baseURL: url)
            if folders.isEmpty {
                cacheFolders = []
                totalSize = 0
                emptyCache = true
                lastOperationResult = .empty
                Log.scanner.info("No folders")
            } else {
                emptyCache = false
                cacheFolders = folders
                totalSize = folders.reduce(0) { $0 + $1.size }
                lastOperationResult = .success(
                    message: String(
                        localized: "cacheAvailableToClean",
                        table: nil
                    ).replacingOccurrences(of: "%@", with: formatSize(totalSize))
                )
                Log.scanner.info("Folders: \(self.cacheFolders)")
            }
        } catch {
            Log.scanner.error("Scan failed: \(error.localizedDescription)")
            fullDiskAccessRequired = true
            lastOperationResult = .failure(message: "Scan failed: \(error.localizedDescription)")
            cacheFolders = []
            totalSize = 0
        }
    }

    func clear(deletePermanently: Bool) async {
        guard requireMailClosed() else {
            Log.access.info("Clear cancelled: Mail is running")
            return
        }

        if cacheFolders.isEmpty {
            lastOperationResult = .empty
            return
        }

        isProcessing = true
        defer { isProcessing = false }
        let urls = cacheFolders.map { $0.url }

        guard let (url, needsStop) = mailFolderURLForAccess() else {
            Log.access.critical("Access denied for clear()")
            fullDiskAccessRequired = true
            lastOperationResult = .failure(message: "Access denied to Mail folder. Full Disk Access may be required.")
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
            let foldersCount = cacheFolders.count
            let freedSize = totalSize
            cacheFolders.removeAll()
            totalSize = 0
            emptyCache = true
            lastOperationResult = .success(message: "\(foldersCount) folder\(foldersCount == 1 ? "" : "s") cleaned · \(formatSize(freedSize)) freed")
        } catch {
            if let mailError = error as? MailCacheDeleter.Error {
                switch mailError {
                case .outsideBasePath(let url):
                    Log.deleter.error("Clear error: outsideBasePath: \(url.path)")
                    lastOperationResult = .failure(message: "Clear failed: path outside allowed base path: \(url.lastPathComponent)")
                case .deletionFailed(let url, let underlying):
                    Log.deleter.error("Clear error: deletionFailed: \(url.path), underlying: \(underlying)")
                    lastOperationResult = .failure(message: "Deletion failed for \(url.lastPathComponent): \(underlying.localizedDescription)")
                case .trashFailed(let url, let underlying):
                    Log.deleter.error("Clear error: trashFailed: \(url.path), underlying: \(underlying)")
                    lastOperationResult = .failure(message: "Moving to Trash failed for \(url.lastPathComponent): \(underlying.localizedDescription)")
                }
            } else {
                Log.deleter.critical("Clear error (unknown): \(error.localizedDescription)")
                lastOperationResult = .failure(message: "Clear failed: \(error.localizedDescription)")
            }
        }
    }
}

