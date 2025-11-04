import XCTest
@testable import MailCleaner

@MainActor
final class ViewModelTests: XCTestCase {
    var scanner: MockScanner!
    var deleter: MockDeleter!
    var sut: MailCleanerViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        scanner = MockScanner()
        deleter = MockDeleter()
        sut = MailCleanerViewModel(scanner: scanner, deleter: deleter)
    }

    override func tearDownWithError() throws {
        scanner = nil
        deleter = nil
        //sut = nil
        try super.tearDownWithError()
    }

    func testEmptyCache() async throws {
        scanner.result = .success([])
        await sut.scan()
        XCTAssertTrue(sut.emptyCache)
        XCTAssertEqual(sut.cacheFolders.count, 0)
        XCTAssertEqual(sut.totalSize, 0)
    }
    
    func testNonEmptyCache() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        scanner.result = .success([info])
        await sut.scan()
        XCTAssertFalse(sut.emptyCache)
        XCTAssertEqual(sut.cacheFolders, [info])
        XCTAssertEqual(sut.totalSize, 123)
    }
    
    func testScanErrorSetsDiskAccessRequired() async throws {
        scanner.result = .failure(NSError(domain: "Test", code: 1))
        await sut.scan()
        XCTAssertTrue(sut.fullDiskAccessRequired)
    }
    
    func testClearDeletesPermanently() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        sut.cacheFolders = [info]
        await sut.clear(deletePermanently: true)
        XCTAssertEqual(deleter.deletedURLs, [info.url])
        XCTAssertEqual(sut.cacheFolders.count, 0)
        XCTAssertEqual(sut.totalSize, 0)
    }
    
    func testClearMovesToTrash() async throws {
        let info = CacheFolderInfo(url: URL(fileURLWithPath: "/tmp/X"), size: 123)
        sut.cacheFolders = [info]
        await sut.clear(deletePermanently: false)
        XCTAssertEqual(deleter.trashedURLs, [info.url])
        XCTAssertEqual(sut.cacheFolders.count, 0)
        XCTAssertEqual(sut.totalSize, 0)
    }
}
