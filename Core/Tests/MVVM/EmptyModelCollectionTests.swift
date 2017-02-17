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
        XCTAssertEqual(emptyModelCollection.sections.count, 1)
        XCTAssertTrue(emptyModelCollection.totalItemCount == 0)
        if case .loaded(let sections) = emptyModelCollection.state {
            XCTAssertTrue(sections.count == 1 && sections.first?.count == 0, "Should include one empty section.")
        } else {
            XCTFail("State should be .loaded got \(emptyModelCollection.state)")
        }

        if case .loaded(let sections) = emptyModelCollection.state {
            XCTAssertTrue(sections.count == 1 && sections.first?.count == 0, "Should include one empty section.")
        } else {
            XCTFail("State should be .loaded got \(emptyModelCollection.state)")
        }
        
        emptyModelCollection.removeObserver(with: observerToken)
        XCTAssertTrue(observerCallCount == 0)
    }
}
