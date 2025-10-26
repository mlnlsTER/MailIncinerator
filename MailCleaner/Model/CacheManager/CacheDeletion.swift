//
//  CacheManager.swift
//

import Foundation


public protocol CacheDeleterProtocol {
    /// Permanently delete given URLs. Throws on first failure.
    func deletePermanently(urls: [URL]) async throws

    /// Move given URLs to Trash.
    func moveToTrash(urls: [URL]) async throws
}

public class MailCacheDeleter: CacheDeleterProtocol {
    public enum Error: Swift.Error {
        case outsideBasePath(URL)
        case deletionFailed(URL, underlying: Swift.Error)
        case trashFailed(URL, underlying: Swift.Error)
    }

    private let fileManager: FileManager
    private let baseCacheURL: URL

    public init(fileManager: FileManager = .default, baseCacheURL: URL? = nil) {
        self.fileManager = fileManager
        if let url = baseCacheURL {
            self.baseCacheURL = url
        } else {
            self.baseCacheURL = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Mail", isDirectory: true)
        }
    }

    private func ensureInsideBase(_ url: URL) throws {
        let base = baseCacheURL.standardizedFileURL.path
        let candidate = url.standardizedFileURL.path
        guard candidate.hasPrefix(base) else { throw Error.outsideBasePath(url) }
    }

    public func deletePermanently(urls: [URL]) async throws {
        for url in urls {
            try ensureInsideBase(url)
            do {
                try fileManager.removeItem(at: url)
            } catch {
                throw Error.deletionFailed(url, underlying: error)
            }
        }
    }

    public func moveToTrash(urls: [URL]) async throws {
        for url in urls {
            try ensureInsideBase(url)
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                throw Error.trashFailed(url, underlying: error)
            }
        }
    }
}
