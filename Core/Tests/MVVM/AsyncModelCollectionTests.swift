import XCTest
@testable import Pilot

private struct TestError: Error {}

class AsyncModelCollectionTests: XCTestCase {

    func testFailure() {
        let provider: AsyncModelCollection.Provider = { callback in
            callback(.error(TestError()))
        }
        let subject = AsyncModelCollection(modelProvider: provider)
        if case .error = subject.state {}
        else { XCTFail("Model collection should be in error state") }
    }

    func testSuccess() {
        let testModel = TM(id: "someId", version: 42)
        let provider: AsyncModelCollection.Provider = { callback in
            callback(.success([[testModel]]))
        }
        let subject = AsyncModelCollection(modelProvider: provider)
        if case .loaded(let sections) = subject.state {
            XCTAssertEqual(sections.count, 1)
            XCTAssertEqual(sections.first?.first?.modelId, testModel.modelId)
        } else {
            XCTFail("Async model collection failed to load")
        }
    }

    func testLoading() {
        var capturedCallback: AsyncModelCollection.Callback? = nil
        let provider: AsyncModelCollection.Provider = { callback in
            capturedCallback = callback
        }
        let subject = AsyncModelCollection(modelProvider: provider)
        XCTAssert(subject.state.isLoading, "AsyncModelCollection should be loading until callback is called")
        capturedCallback?(.error(TestError()))
        XCTAssert(!subject.state.isLoading, "AsyncModelCollection should not be loading after callback is called")
    }
}
