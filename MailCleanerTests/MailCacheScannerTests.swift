//
//  MailScannerTests.swift
//  MailScannerTests
//
//  Created by Zhdan Baliuk on 30.10.2025.
//

import XCTest
@testable import MailCleaner

final class MailCacheScannerTests: XCTestCase {
    
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tempDir)
    }
    
    private func createFile(at path: String, size: Int) throws {
        let url = tempDir.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = Data(repeating: 0x0A, count: size)
        try data.write(to: url)
    }

    func testScanFindsOnlyVDirectories() async throws {
        try FileManager.default.createDirectory(at: tempDir.appendingPathComponent("V10"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tempDir.appendingPathComponent("Vaa"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tempDir.appendingPathComponent("MailData"), withIntermediateDirectories: true)
        
        let scanner = await MailCacheScanner(baseCacheURL: tempDir)
        let result = try await scanner.scan()
        XCTAssertTrue(result.isEmpty, "Expected no directories")
    }
    
    func testIgnoresMailDataSubfolder() async throws {
           let vDir = tempDir.appendingPathComponent("V10")
           let mailDataDir = vDir.appendingPathComponent("MailData")
           try FileManager.default.createDirectory(at: mailDataDir, withIntermediateDirectories: true)

           let cacheDir = vDir.appendingPathComponent("TestCache")
           try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
           try createFile(at: "V10/TestCache/file.bin", size: 1024)

        let scanner = await MailCacheScanner(baseCacheURL: tempDir)
           let result = try await scanner.scan()

           XCTAssertEqual(result.count, 1)
           XCTAssertEqual(result.first?.url.lastPathComponent, "TestCache")
           XCTAssertEqual(result.first?.size, 1024)
       }

       func testThrowsBaseNotFound() async {
           let notExisting = tempDir.appendingPathComponent("NoSuchDir")
           let scanner = await MailCacheScanner(baseCacheURL: notExisting)
           do {
               _ = try await scanner.scan()
               XCTFail("Expected baseNotFound")
           } catch MailCacheScanner.Error.baseNotFound {
               // ok
           } catch {
               XCTFail("Unexpected error: \(error)")
           }
       }

       func testEmptyBaseReturnsEmptyArray() async throws {
           let scanner = await MailCacheScanner(baseCacheURL: tempDir)
           let result = try await scanner.scan()
           XCTAssertTrue(result.isEmpty)
       }

       func testDirectorySizeCalculation() async throws {
           try FileManager.default.createDirectory(at: tempDir.appendingPathComponent("V10"), withIntermediateDirectories: true)
           let sub = tempDir.appendingPathComponent("Dir")
           try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
           try createFile(at: "V10/Dir/a.bin", size: 200)
           try createFile(at: "V10/Dir/b.bin", size: 300)

           let scanner = await MailCacheScanner(baseCacheURL: tempDir)
           let result = try await scanner.scan()
           
           var size: Int64 = 0
           for res in result {
               await size += res.size
           }
           
           XCTAssertEqual(size, 500)
       }

}
