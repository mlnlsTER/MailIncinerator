//
//  MailCleanerDependencies.swift
//  MailCleaner
//
//  Created by Zhdan Baliuk on 21.11.2025.
//

import Foundation

public enum AppMode {
    case `public`
    case appstore
}

protocol MailCleanerDependencies {
    var mode: AppMode { get }
    var baseURL: URL? { get }
    var scanner: CacheScannerProtocol { get }
    var deleter: CacheDeleterProtocol { get }
}

struct ProdDependencies: MailCleanerDependencies {
    let mode: AppMode
    let baseURL: URL?
    let scanner: CacheScannerProtocol
    let deleter: CacheDeleterProtocol

    init(mode: AppMode, baseURL: URL? = nil) {
        self.mode = mode
        self.baseURL = baseURL
        self.scanner = MailCacheScanner(baseCacheURL: baseURL)
        self.deleter = MailCacheDeleter(baseCacheURL: baseURL)
    }
}

struct MockDependencies: MailCleanerDependencies {
    let mode: AppMode
    let baseURL: URL?
    let scanner: CacheScannerProtocol
    let deleter: CacheDeleterProtocol

    init(
        mode: AppMode,
        baseURL: URL? = nil,
        scanner: CacheScannerProtocol,
        deleter: CacheDeleterProtocol
    ) {
        self.mode = mode
        self.baseURL = baseURL
        self.scanner = scanner
        self.deleter = deleter
    }
}

