//
//  ViewModel.swift
//  MailCleaner
//
//  Created by Zhdan Baliuk on 23.10.2025.
//

import Foundation
internal import Combine

final class MailCleanerViewModel: ObservableObject {
    @Published var cacheFolders: [CacheFolderInfo] = []
    @Published var totalSize: Int64 = 0
    @Published var isScanning: Bool = false
    @Published var progress: Double = 0.0
    
    private let scanner = MailCacheScanner()
    private let deleter = MailCacheDeleter()
    
    func scan() async {
        isScanning = true
        progress = 0.0
        fullDiskAccessRequired = false
        defer { isScanning = false }
        do {
            let folders = try await scanner.scan()
            let total = folders.count
            var loaded = 0

            cacheFolders.removeAll()
            for folder in folders {
                loaded += 1
                cacheFolders.append(folder)
                totalSize = cacheFolders.reduce(0) { $0 + $1.size }
                progress = Double(loaded) / Double(total)
                try await Task.sleep(nanoseconds: 20_000_000)
            }
        } catch {
            if let mailError = error as? MailCacheScanner.Error, mailError == .baseNotFound {
                fullDiskAccessRequired = true
            }
            print("Scan failed: \(error.localizedDescription)")
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
