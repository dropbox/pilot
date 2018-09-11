#if !canImport(RxSwift)

@testable import Pilot
import XCTest

class SemaphoreExpectation {
    init(_ testCase: XCTestCase) {
        self.testCase = testCase
    }

    func inc() {
        let expectation = testCase.expectation(description: "semaphore")
        expectations.append(expectation)
    }

    func dec() {
        expectations.popLast()!.fulfill()
    }

    private let testCase: XCTestCase
    private var expectations: [XCTestExpectation] = []
}

class ObservableTests: XCTestCase {
    var observer: Subscription?

    func testObservableVariable() {
        let variable = ObservableVariable<String>.make(withEquatable: "initial")
        var events = [String]()

        let expectation = SemaphoreExpectation(self)

        observer = variable.observeValues({ event in
            events.append(event)
            expectation.dec()
        })
        expectation.inc()
        variable.data = "hello"
        expectation.inc()
        variable.data = "world"

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(["hello", "world"], events)
    }
}

#endif // !RxSwift
