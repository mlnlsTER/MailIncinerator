//
//  ViewModel.swift
//  MailCleaner
//

import Foundation
import AppKit
import Combine

final class MailCleanerViewModel: ObservableObject {

    @Published var cacheFolders: [CacheFolderInfo] = []
    @Published var totalSize: Int64 = 0
    @Published var isScanning: Bool = false
    @Published var fullDiskAccessRequired: Bool = false
    @Published var emptyCache: Bool = true
    
    private let scanner: CacheScannerProtocol
    private let deleter: CacheDeleterProtocol

    init(scanner: CacheScannerProtocol = MailCacheScanner(),
         deleter: CacheDeleterProtocol = MailCacheDeleter()) {
        self.scanner = scanner
        self.deleter = deleter
    }

    func scan() async {
        isScanning = true
        defer { isScanning = false }
        do {
            let folders = try await scanner.scan(baseURL: nil)
            let total = folders.count
            guard total > 0 else {
                emptyCache = true
                return
            }
            emptyCache = false
            cacheFolders.removeAll()
            for folder in folders {
                cacheFolders.append(folder)
                totalSize = cacheFolders.reduce(0) { $0 + $1.size }
            }
        } catch {
            print("Scan failed: \(error.localizedDescription)")
            fullDiskAccessRequired = true
        }
    }
    
    func clear(deletePermanently: Bool) async {
        let urls = cacheFolders.map { $0.url }
        do {
            if deletePermanently {
                try await deleter.deletePermanently(urls: urls)
            } else {
                try await deleter.moveToTrash(urls: urls)
            }
            cacheFolders.removeAll()
            totalSize = 0
        } catch {
            print("Clear error:", error.localizedDescription)
        }
    }
}
