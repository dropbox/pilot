@testable import Pilot
import XCTest

class CompoundActionTests: XCTestCase {

    struct StubAction: Action {
        let identifier = Token.makeUnique()
    }

    func testSendsAllChildActions() {
        let childOne = StubAction()
        let childTwo = StubAction()
        let subject = CompoundAction(childActions: [childOne, childTwo])
        let context = Context()
        var receivedOne = false
        var receivedTwo = false
        let obs = context.receive({ (action: StubAction) -> ActionResult in
            if action.identifier == childOne.identifier { receivedOne = true }
            if action.identifier == childTwo.identifier { receivedTwo = true }
            return .handled
        })
        subject.send(from: context)
        XCTAssertTrue(receivedOne)
        XCTAssertTrue(receivedTwo)
        _ = obs
    }

    func testNotHandled() {
        let childOne = StubAction()
        let childTwo = StubAction()
        let subject = CompoundAction(childActions: [childOne, childTwo])
        let context = Context()
        let obs = context.receiveAll { _ in return .notHandled }
        let result = subject.send(from: context)
        XCTAssertEqual(result, .notHandled)
        _ = obs
    }

    func testHandled() {
        let childOne = StubAction()
        let childTwo = StubAction()
        let subject = CompoundAction(childActions: [childOne, childTwo])
        let context = Context()
        let obs = context.receive { (action: StubAction) -> ActionResult in
            if action.identifier == childTwo.identifier { return .handled }
            return .notHandled
        }
        let result = subject.send(from: context)
        XCTAssertEqual(result, .handled)
        _ = obs
    }

    func testWithFuncFlattensOutCompoundActions() {
        let s1 = StubAction()
        let s2 = StubAction()
        let subject = CompoundAction(childActions: [s1])
        let result = subject.with(CompoundAction(childActions: [s2]))
        let identifiers = result.childActions.flatMap { (action) -> Token? in
            if let act = action as? StubAction {
                return act.identifier
            }
            XCTFail("Unexpected action type \(action)")
            return nil
        }
        XCTAssertEqual([s1.identifier, s2.identifier], identifiers)
    }
}

