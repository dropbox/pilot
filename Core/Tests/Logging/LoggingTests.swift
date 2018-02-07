@testable import Pilot
import XCTest

class LoggingTests: XCTestCase {

    // MARK: XCTestCase

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        do {
            for url in urlsToMoveToTrash {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            XCTAssert(false)
        }
        super.tearDown()
    }

    private var urlsToMoveToTrash: [URL] = []

    func testLog() {
        let expectation = self.expectation(description: "logHub completion")
        let testLogger = TestLogger(expectation: expectation)
        let loggerToken = Log.addLogger(testLogger)
        Log.info(.domain("pilot.tests"), message: "XCTests are cool")
        waitForExpectations(timeout: 2.0, handler: nil)
        Log.removeLogger(loggerToken)
    }

    func testConsoleLogger() {
        let expectation = self.expectation(description: "expect sentinel to return")
        let consoleLogger = ConsoleLogger()
        let loggerToken = Log.addLogger(consoleLogger)
        Log.info(.domain("pilot.tests"), message: "This should appear in console")
        Log.sendSentinelThroughQueue("Elephant in Cairo") { sentinel in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        Log.removeLogger(loggerToken)
    }

    private func makeTestURLForFileLogger() throws -> URL {
        let cachesDirectoryUrl = try FileManager.default.url(
            for: FileManager.SearchPathDirectory.cachesDirectory,
            in: FileManager.SearchPathDomainMask.userDomainMask,
            appropriateFor:nil,
            create: true)
        let uniqueString = UUID().uuidString
        return cachesDirectoryUrl.appendingPathComponent("loggingTest-" + uniqueString)
    }
}

struct TestLogger: Logger {
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    func log(_ message: String, date: Date, severity: Log.Severity, category: Log.Category) {
        XCTAssert(message == "XCTests are cool")
        XCTAssert(Log.Severity.info == severity)
        guard case .domain(let domain) = category else { XCTAssert(false);  return }
        XCTAssert(domain == "pilot.tests")
        expectation.fulfill()
    }
    private let expectation: XCTestExpectation
}
