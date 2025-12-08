import Foundation

public struct CacheFolderInfo: Equatable {
    public let url: URL
    public let size: Int64
}

public protocol CacheScannerProtocol {
    func scan(baseURL: URL?) async throws -> [CacheFolderInfo]
}

public struct MailCacheScanner: CacheScannerProtocol, Equatable {
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
            
            let subfolderInfos = try await withThrowingTaskGroup(of: CacheFolderInfo?.self) { group in
                for candidate in vContents {
                    group.addTask {
                        if candidate.lastPathComponent == "MailData" { return nil }
                        var isDir: ObjCBool = false
                        let localFileManager = FileManager()
                        if localFileManager.fileExists(atPath: candidate.path, isDirectory: &isDir), isDir.boolValue {
                            // Safety: ensure candidate path is contained within base
                            guard candidate.resolvingSymlinksInPath().path.hasPrefix(base.resolvingSymlinksInPath().path + "/") else {
                                throw Error.invalidCandidate(candidate)
                            }
                            // Calculate the size of the catalog
                            let size = try await directorySize(at: candidate)
                            return CacheFolderInfo(url: candidate, size: size)
                        }
                        return nil
                    }
                }
                var subfolderInfos: [CacheFolderInfo] = []
                for try await info in group {
                    if let info = info {
                        subfolderInfos.append(info)
                    }
                }
                return subfolderInfos
            }
            result.append(contentsOf: subfolderInfos)
        }
        return result
    }

    //MARK: - Calculating total size of directory
    private func directorySize(at url: URL) async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                var total: Int64 = 0
                guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey], options: [.skipsHiddenFiles]) else {
                    continuation.resume(returning: 0)
                    return
                }
                for case let fileURL as URL in enumerator {
                    if Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    autoreleasepool {
                        if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            total += Int64(size)
                        }
                    }
                }
                continuation.resume(returning: total)
            }
        }
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

