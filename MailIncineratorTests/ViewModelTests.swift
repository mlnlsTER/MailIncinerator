//
//  ViewModelTests.swift
//  MailScannerTests
//
//  Created by mlnlsTER on 30.10.2025.
//

import XCTest
@testable import MailIncinerator

@MainActor
final class ViewModelTests: XCTestCase {
    var scanner: MockScanner!
    var deleter: MockDeleter!
    var sutMAS: MailCleanerViewModel!
    var sutPublic: MailCleanerViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        scanner = MockScanner()
        deleter = MockDeleter()
        let tempURL = URL(fileURLWithPath: "/tmp")
        sutMAS = MailCleanerViewModel(
            dependencies: MockDependencies(mode: .appstore, baseURL: nil, scanner: scanner, deleter: deleter)
        )
        sutPublic = MailCleanerViewModel(
            dependencies: MockDependencies(mode: .public, baseURL: tempURL, scanner: scanner, deleter: deleter)
        )
    }

    override func tearDownWithError() throws {
        scanner = nil
        deleter = nil
        //sutMAS = nil
        //sutPublic = nil
        try super.tearDownWithError()
    }

    // MARK: - AppStore Mode Tests

    func testMAS_EmptyCache() async throws {
        scanner.result = .success([])
        await sutMAS.scan()
        XCTAssertTrue(sutMAS.emptyCache)
        XCTAssertEqual(sutMAS.cacheFolders.count, 0)
        XCTAssertEqual(sutMAS.totalSize, 0)
    }
    
    func testMAS_NonEmptyCache() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        scanner.result = .success([info])
        await sutMAS.scan()
        XCTAssertFalse(sutMAS.emptyCache)
        XCTAssertEqual(sutMAS.cacheFolders, [info])
        XCTAssertEqual(sutMAS.totalSize, 123)
    }
    
    func testMAS_ScanErrorSetsDiskAccessRequired() async throws {
        scanner.result = .failure(NSError(domain: "Test", code: 1))
        await sutMAS.scan()
        XCTAssertTrue(sutMAS.fullDiskAccessRequired)
    }
    
    func testMAS_ClearDeletesPermanently() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        sutMAS.cacheFolders = [info]
        await sutMAS.clear(deletePermanently: true)
        XCTAssertEqual(deleter.deletedURLs, [info.url])
        XCTAssertEqual(sutMAS.cacheFolders.count, 0)
        XCTAssertEqual(sutMAS.totalSize, 0)
    }
    
    func testMAS_ClearMovesToTrash() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        sutMAS.cacheFolders = [info]
        await sutMAS.clear(deletePermanently: false)
        XCTAssertEqual(deleter.trashedURLs, [info.url])
        XCTAssertEqual(sutMAS.cacheFolders.count, 0)
        XCTAssertEqual(sutMAS.totalSize, 0)
    }

    // MARK: - Public Mode Tests

    func testPublic_EmptyCache() async throws {
        scanner.result = .success([])
        await sutPublic.scan()
        XCTAssertTrue(sutPublic.emptyCache)
        XCTAssertEqual(sutPublic.cacheFolders.count, 0)
        XCTAssertEqual(sutPublic.totalSize, 0)
    }
    
    func testPublic_NonEmptyCache() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        scanner.result = .success([info])
        await sutPublic.scan()
        XCTAssertFalse(sutPublic.emptyCache)
        XCTAssertEqual(sutPublic.cacheFolders, [info])
        XCTAssertEqual(sutPublic.totalSize, 123)
    }
    
    func testPublic_ScanErrorSetsDiskAccessRequired() async throws {
        scanner.result = .failure(NSError(domain: "Test", code: 1))
        await sutPublic.scan()
        XCTAssertTrue(sutPublic.fullDiskAccessRequired)
    }
    
    func testPublic_ClearDeletesPermanently() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        sutPublic.cacheFolders = [info]
        await sutPublic.clear(deletePermanently: true)
        XCTAssertEqual(deleter.deletedURLs, [info.url])
        XCTAssertEqual(sutPublic.cacheFolders.count, 0)
        XCTAssertEqual(sutPublic.totalSize, 0)
    }
    
    func testPublic_ClearMovesToTrash() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        sutPublic.cacheFolders = [info]
        await sutPublic.clear(deletePermanently: false)
        XCTAssertEqual(deleter.trashedURLs, [info.url])
        XCTAssertEqual(sutPublic.cacheFolders.count, 0)
        XCTAssertEqual(sutPublic.totalSize, 0)
    }
}

