//
//  CacheScanner.swift
//

import Foundation

public struct CacheFolderInfo: Equatable {
    public let url: URL
    public let size: Int64
}

public protocol CacheScannerProtocol {
    func scan(baseURL: URL?) async throws -> [CacheFolderInfo]
}

public struct MailCacheScanner: CacheScannerProtocol {
    public enum Error: Swift.Error {
        case baseNotFound
        case invalidCandidate(URL)
    }

    private let fileManager: FileManager
    private let baseCacheURL: URL

    // Parameter baseCacheURL: explicit base cache URL. If nil, resolves to ~/Library/Mail
    public init(fileManager: FileManager = .default, baseCacheURL: URL? = nil) {
        self.fileManager = fileManager
        if let url = baseCacheURL {
            self.baseCacheURL = url
        } else {
            self.baseCacheURL = URL(filePath: CacheConstants.mailPath)
        }
    }

    public func scan(baseURL: URL? = nil) async throws -> [CacheFolderInfo] {
        let base = baseURL ?? baseCacheURL
        guard fileManager.fileExists(atPath: base.path) else {
            throw Error.baseNotFound
        }

        // List children of base. Find directories named starting with "V" followed by digits.
        let contents = try fileManager.contentsOfDirectory(at: base, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

        var result = [CacheFolderInfo]()

        for item in contents {
            let name = item.lastPathComponent
            guard name.count >= 3, name.first == "V" else { continue }
            let suffix = name.dropFirst()
            guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: String(suffix))) else { continue }

            // Inside V# directory, gather its top-level folders except MailData and non-directories
            let vContents = try fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            for candidate in vContents {
                if candidate.lastPathComponent == "MailData" { continue }
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: candidate.path, isDirectory: &isDir), isDir.boolValue {

                    // Safety: ensure candidate path is contained within base
                    let baseResolved = base.resolvingSymlinksInPath()
                    let candidateResolved = candidate.resolvingSymlinksInPath()
                    guard candidateResolved.path.hasPrefix(baseResolved.path + "/") else {
                        throw Error.invalidCandidate(candidate)
                    }
                    
                    // Calculate the size of the catalog
                    let size = try await directorySize(at: candidate)
                    result.append(CacheFolderInfo(url: candidate, size: size))
                }
            }
        }
        return result
    }

    //MARK: - Recursively calculates the total size of a directory (in bytes).
    private func directorySize(at url: URL) async throws -> Int64 {
        var size: Int64 = 0
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]

        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            if resourceValues.isDirectory == true {
                continue
            }
            if let fileSize = resourceValues.fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }
}

final class MockScanner: CacheScannerProtocol {
    var result: Result<[CacheFolderInfo], Error> = .success([])
    
    func scan(baseURL: URL?) async throws -> [CacheFolderInfo] {
        switch result {
        case .success(let folders): return folders
        case .failure(let error): throw error
        }
    }
}

