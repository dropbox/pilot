@testable import Pilot
import XCTest

class SwitchableModelCollectionTests: XCTestCase {

    func testForwardsState() {
        let stub = SimpleModelCollection()
        let subject = SwitchableModelCollection(modelCollection: stub)
        assertModelCollectionState(expected: stub.state, actual: subject.state)
        stub.onNext(.loading(nil))
        assertModelCollectionState(expected: stub.state, actual: subject.state)
    }

    func testSendsEventWhenSwitched() {
        let simple = SimpleModelCollection()
        simple.onNext(.loading(nil))
        let subject = SwitchableModelCollection(modelCollection: simple)
        let exp = expectation(description: "observer event")
        let observer = subject.observeValues { (event) in
            if case .didChangeState(let state) = event {
                if case .loaded(let models) = state {
                    XCTAssert(models.isEmpty == true, "Should be empty collection")
                    exp.fulfill()
                }
            }
        }
        let empty = EmptyModelCollection()
        subject.switchTo(empty)
        waitForExpectations(timeout: 1, handler: nil)
        assertModelCollectionState(expected: empty.state, actual: subject.state)
        _ = observer
    }

    func testUnsubscribesWhenSwitched() {
        let old = SimpleModelCollection()
        let subject = SwitchableModelCollection(modelCollection: old)
        let new = SimpleModelCollection()
        new.onNext(.loaded([]))
        subject.switchTo(new)
        old.onNext(.loading(nil))
        assertModelCollectionState(expected: new.state, actual: subject.state)
    }

    func testSwitchableSectioned() {
        let old = SimpleModelCollection()
        old.onNext(.loaded([]))
        let subject = SwitchableModelCollection(modelCollection: old)
        assertSectionedModelCollectionState(expected: subject.asSectioned().sectionedState, actual: [.loaded([])])
        let newLoading = SimpleModelCollection()
        newLoading.onNext(.loading(nil))
        let new = ComposedModelCollection.multiplexing([old, newLoading])
        subject.switchTo(new)
        assertSectionedModelCollectionState(
            expected: subject.asSectioned().sectionedState,
            actual: [.loaded([]), .loading(nil)])
    }
}
