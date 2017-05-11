@testable import Pilot
import XCTest

class CompoundActionTests: XCTestCase {

    struct StubAction: Action {
        let identifier = Token.makeUnique()
    }

    func testSendsAllChildActions() {
        let actionOne = StubAction()
        let actionTwo = StubAction()
        let subject = CompoundAction([actionOne, actionTwo])
        let context = Context()
        var receivedOne = false
        var receivedTwo = false
        let obs = context.receive({ (action: StubAction) -> ActionResult in
            if action.identifier == actionOne.identifier { receivedOne = true }
            if action.identifier == actionTwo.identifier { receivedTwo = true }
            return .handled
        })
        subject.send(from: context)
        XCTAssertTrue(receivedOne)
        XCTAssertTrue(receivedTwo)
        _ = obs
    }

    func testNotHandled() {
        let actionOne = StubAction()
        let actionTwo = StubAction()
        let subject = CompoundAction([actionOne, actionTwo])
        let context = Context()
        let obs = context.receiveAll { _ in return .notHandled }
        let result = subject.send(from: context)
        XCTAssertEqual(result, .notHandled)
        _ = obs
    }

    func testHandled() {
        let actionOne = StubAction()
        let actionTwo = StubAction()
        let subject = CompoundAction([actionOne, actionTwo])
        let context = Context()
        let obs = context.receive { (action: StubAction) -> ActionResult in
            if action.identifier == actionTwo.identifier { return .handled }
            return .notHandled
        }
        let result = subject.send(from: context)
        XCTAssertEqual(result, .handled)
        _ = obs
    }

    func testWithFuncFlattensOutCompoundActions() {
        let s1 = StubAction()
        let s2 = StubAction()
        let subject = CompoundAction([s1])
        let result = subject.with(CompoundAction([s2]))
        let identifiers = result.actions.flatMap { (action) -> Token? in
            if let act = action as? StubAction {
                return act.identifier
            }
            XCTFail("Unexpected action type \(action)")
            return nil
        }
        XCTAssertEqual([s1.identifier, s2.identifier], identifiers)
    }
}
