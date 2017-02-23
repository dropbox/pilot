import XCTest
@testable import Pilot

private struct TestError: Error {}

class AsyncModelCollectionTests: XCTestCase {

    func testFailure() {
        let provider: AsyncModelCollection.Provider = { callback in
            callback(.error(TestError()))
        }
        let subject = AsyncModelCollection(modelProvider: provider)
        subject.fetch()
        if case .error = subject.state {}
        else { XCTFail("Model collection should be in error state") }
    }

    func testSuccess() {
        let testModel = TM(id: "someId", version: 42)
        let provider: AsyncModelCollection.Provider = { callback in
            callback(.success([[testModel]]))
        }
        let subject = AsyncModelCollection(modelProvider: provider)
        subject.fetch()
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
        subject.fetch()
        XCTAssert(subject.state.isLoading, "AsyncModelCollection should be loading until callback is called")
        capturedCallback?(.error(TestError()))
        XCTAssert(!subject.state.isLoading, "AsyncModelCollection should not be loading after callback is called")
    }

    func testStartsNotLoaded() {
        let subject = AsyncModelCollection(modelProvider: { _ in
            XCTFail("Model provider should not be called before `fetch()`")
        })
        if case .notLoaded = subject.state {
            // pass
        } else {
            XCTFail("AsyncModelCollection should be notLoaded before `fetch()` is called")
        }
    }

    func testLoadingStateMultipleFetches() {
        var capturedCallback: AsyncModelCollection.Callback? = nil
        let provider: AsyncModelCollection.Provider = { callback in
            capturedCallback = callback
        }
        let subject = AsyncModelCollection(modelProvider: provider)
        subject.fetch()
        if case .loading(let sections) = subject.state {
            XCTAssertNil(sections, "Sections should be nil first time fetch() is called before modelProvider returns")
        } else {
            XCTFail("State should be .loading(nil) got \(subject.state)")
        }
        // First load
        let testModel = TM(id: "someId", version: 42)
        capturedCallback?(.success([[testModel]]))
        // Start second load
        subject.fetch()
        if case .loading(let sections) = subject.state {
            XCTAssertNotNil(sections, "sections should not be nil the if fetch() is called after a successful load")
            XCTAssertEqual(sections?.count, 1)
            XCTAssertEqual(sections?.first?.first?.modelId, testModel.modelId)
        } else {
            XCTFail("State should be .loading(nil) got \(subject.state)")
        }
    }

    func testCallbackOverwritesSections() {
        var capturedCallback: AsyncModelCollection.Callback? = nil
        let provider: AsyncModelCollection.Provider = { callback in
            capturedCallback = callback
        }
        let subject = AsyncModelCollection(modelProvider: provider)
        subject.fetch()
        let testModel = TM(id: "someId", version: 42)
        capturedCallback?(.success([[testModel]]))
        // Start second load
        subject.fetch()
        let testModel2 = TM(id: "someId2", version: 43)
        capturedCallback?(.success([[testModel2]]))
        if case .loaded(let sections) = subject.state {
            XCTAssertEqual(sections.count, 1)
            XCTAssertEqual(sections.first?.first?.modelId, testModel2.modelId)
        } else {
            XCTFail("Async model collection failed to load")
        }
    }
}
