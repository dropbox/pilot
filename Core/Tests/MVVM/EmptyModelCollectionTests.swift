@testable import Pilot
import XCTest

class EmptyModelCollectionTests: XCTestCase {

    func testEmptyModelCollection() {
        var observerCallCount = 0
        let emptyModelCollection = EmptyModelCollection()
        let observerToken = emptyModelCollection.addObserver() { event in
            observerCallCount = observerCallCount + 1
        }
        XCTAssertTrue(emptyModelCollection.collectionId.hasPrefix("empty"))
        XCTAssertTrue(emptyModelCollection.state.isEmpty)

        if case .loaded(let models) = emptyModelCollection.state {
            XCTAssertTrue(models.count == 0, "Should be an empty section.")
        } else {
            XCTFail("State should be .loaded got \(emptyModelCollection.state)")
        }

        if case .loaded(let models) = emptyModelCollection.state {
            XCTAssertTrue(models.count == 0, "Should be an empty section.")
        } else {
            XCTFail("State should be .loaded got \(emptyModelCollection.state)")
        }
        
        emptyModelCollection.removeObserver(with: observerToken)
        XCTAssertTrue(observerCallCount == 0)
    }
}
