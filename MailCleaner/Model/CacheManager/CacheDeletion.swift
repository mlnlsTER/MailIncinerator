import Foundation

public protocol CacheDeleterProtocol {
    func deletePermanently(urls: [URL]) async throws

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
            self.baseCacheURL = URL(filePath: CacheConstants.mailPath)
        }
    }

    private func ensureInsideBase(_ url: URL) throws {
        let base = baseCacheURL.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        let candidate = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        guard candidate.starts(with: base) else { throw Error.outsideBasePath(url) }
        
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
        var resultingItemURL: NSURL?
        for url in urls {
            try ensureInsideBase(url)
            do {
                try fileManager.trashItem(at: url, resultingItemURL: &resultingItemURL)
            } catch {
                throw Error.trashFailed(url, underlying: error)
            }
        }
    }
}

final class MockDeleter: CacheDeleterProtocol {
    var deletedURLs: [URL] = []
    var trashedURLs: [URL] = []
    var shouldThrow = false
    
    func deletePermanently(urls: [URL]) async throws {
        if shouldThrow { throw NSError(domain: "Test", code: 1) }
        deletedURLs.append(contentsOf: urls)
    }
    func moveToTrash(urls: [URL]) async throws {
        if shouldThrow { throw NSError(domain: "Test", code: 2) }
        trashedURLs.append(contentsOf: urls)
    }
}
