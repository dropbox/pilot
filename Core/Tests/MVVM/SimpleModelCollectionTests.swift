import XCTest
@testable import Pilot

class SimpleModelCollectionTests: XCTestCase {

    func testShouldStartNotLoaded() {
        let simple = SimpleModelCollection()
        XCTAssert(simple.state.isNotLoaded, "SimpleModelCollection should be notLoaded before there are any events")
    }

    func testShouldPropegateLoading() {
        let simple = SimpleModelCollection()
        simple.onNext(.loading(nil))
        XCTAssert(simple.state.isLoading, "SimpleModelCollection should be loading after receiving loading event")
    }

    func testShouldPropegateModels() {
        let simple = SimpleModelCollection()
        let test = TM(id: "stub", version: 1)
        simple.onNext(.loaded([test]))
        let first = simple.state.models
        XCTAssertEqual(first.first?.modelId, test.modelId)
        XCTAssertEqual(first.count, 1)
    }

    func testShouldPropegateLoadingMore() {
        let simple = SimpleModelCollection()
        let test = TM(id: "stub", version: 1)
        simple.onNext(.loading([test]))
        let first = simple.state.models
        XCTAssert(simple.state.isLoading)
        XCTAssertEqual(first.first?.modelId, test.modelId)
        XCTAssertEqual(first.count, 1)
    }
}
