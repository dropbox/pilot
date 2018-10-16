import XCTest
import RxSwift
import RxTest
import RxBlocking
@testable import Pilot

class SimpleModelCollectionTests: XCTestCase {

    func testShouldStartNotLoaded() {
        XCTAssertTrue(try SimpleModelCollection().take(1).toBlocking().first()?.isNotLoaded == true)
    }

    func testShouldPropegateLoading() {
        let subject = SimpleModelCollection()
        scheduler.scheduleAt(210) {
            subject.onNext(.loading(nil))
        }
        let result = scheduler.start { subject.map({ $0.isLoading }) }
        let expected: [Recorded<RxSwift.Event<Bool>>] = [
            next(200, false),
            next(210, true)
        ]
        XCTAssertEqual(result.events, expected)
    }

    func testShouldPropegateModels() {
        let subject = SimpleModelCollection()
        let test = TM(id: "stub", version: 1)
        scheduler.scheduleAt(210) {
            subject.onNext(.loaded([test]))
        }
        let result = scheduler.start { subject.map({ $0.models.map({ $0.modelId }) }) }
        let expected: [Recorded<RxSwift.Event<[ModelId]>>] = [
            next(200, []),
            next(210, [test.modelId])
        ]
        XCTAssertEqual(result.events, expected)
    }

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
    }

    private var scheduler: TestScheduler!
}
