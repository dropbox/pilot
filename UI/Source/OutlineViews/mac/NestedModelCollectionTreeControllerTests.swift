import XCTest
import Pilot
@testable import PilotUI

class LazyNestedModelCollectionTreeTests: XCTestCase {

    func testNestedIndex() {
        let mc: TestMC = [("A", [("A.1", nil), ("A.2", [("A.2.a", nil)])])]
        let subject = NestedModelCollectionTreeController(modelCollection: mc)
        XCTAssertEqual(subject.modelAtIndexPath([0]).modelId, "A")
        XCTAssertEqual(subject.modelAtIndexPath([0, 0]).modelId, "A.1")
        XCTAssertEqual(subject.modelAtIndexPath([0, 1]).modelId, "A.2")
        XCTAssertEqual(subject.modelAtIndexPath([0, 1, 0]).modelId, "A.2.a")
    }

    func testCanExpand() {
        let mc: TestMC = [("A", [("A.1", nil), ("A.2", [("A.2.a", nil)])])]
        let subject = NestedModelCollectionTreeController(modelCollection: mc)
        XCTAssert(!subject.isExpandable([0, 0]))
        XCTAssert(subject.isExpandable([0, 1]))
    }

    func testCountChildren() {
        let mc: TestMC = [("A", [("A.1", nil), ("A.2", [("A.2.a", nil)])])]
        let subject = NestedModelCollectionTreeController(modelCollection: mc)
        XCTAssertEqual(subject.countOfChildNodes([]), 1)
        XCTAssertEqual(subject.countOfChildNodes([0]), 2)
        XCTAssertEqual(subject.countOfChildNodes([0, 0]), 0)
    }

    func testIsLazy() {
        let childMC: TestMC = [("A.2.a", nil)]
        let parentMC: TestMC = [("A", [("A.1", nil), ("A.2", childMC)])]
        let subject = NestedModelCollectionTreeController(modelCollection: parentMC)
        let spy = TestObserver(subject)
        childMC.state = .loaded([TestM("A.2.a"), TestM("A.2.b")])
        XCTAssertNil(spy.events.first, "Shouldn't notify for child nodes when parent hasn't expanded")
    }

    func testUpdatesNestedItem() {
        let childMC: TestMC = [("A.2.a", nil)]
        let parentMC: TestMC = [("A", [("A.1", nil), ("A.2", childMC)])]
        let subject = NestedModelCollectionTreeController(modelCollection: parentMC)
        let spy = TestObserver(subject)
        _ = subject.modelAtIndexPath([0, 1, 0])
        childMC.state = .loaded([TestM("A.2.a", version: ModelVersion(UInt64(2)))])
        assertEqual(spy.events.first?.updated, [[0, 1, 0]])
    }

    func testInsertsNestedItem() {
        let childMC: TestMC = [("A.2.a", nil)]
        let parentMC: TestMC = [("A", [("A.1", nil), ("A.2", childMC)])]
        let subject = NestedModelCollectionTreeController(modelCollection: parentMC)
        let spy = TestObserver(subject)
        _ = subject.modelAtIndexPath([0, 1, 0])
        childMC.state = .loaded([TestM("A.2.a"), TestM("A.2.b")])
        assertEqual(spy.events.first?.added, [[0, 1, 1]])
    }

    func testDeletesShiftsSiblingIndexPaths() {
        let grandchildMC: TestMC = [("A.2.a", nil)]
        let childMC: TestMC = [("A.1", nil), ("A.2", grandchildMC)]
        let parentMC: TestMC = [("A", childMC)]
        let subject = NestedModelCollectionTreeController(modelCollection: parentMC)
        let spy = TestObserver(subject)
        _ = subject.modelAtIndexPath([0, 1, 0])
        childMC.state = .loaded([(TestM("A.2"))])
        grandchildMC.state = .loaded([TestM("A.2.a"), TestM("A.2.b")])
        XCTAssertEqual(spy.events.count, 2)
        assertEqual(spy.events.last?.added, [[0,0,1]])
    }

    func testIgnoresUpdatesAfterDelete() {
        let grandchildMC: TestMC = [("A.2.a", nil)]
        let childMC: TestMC = [("A.1", nil), ("A.2", grandchildMC)]
        let parentMC: TestMC = [("A", childMC)]
        let subject = NestedModelCollectionTreeController(modelCollection: parentMC)
        let spy = TestObserver(subject)
        _ = subject.modelAtIndexPath([0, 1, 0])
        childMC.state = .loaded([(TestM("A.1"))])
        grandchildMC.state = .loaded([TestM("A.2.a"), TestM("A.2.b")])
        XCTAssertEqual(spy.events.count, 1)
    }

    private func assertEqual<T: Equatable>(
        _ lhs: @autoclosure () -> [T]?,
        _ rhs: @autoclosure () -> [T]?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let lhsValue = lhs()
        let rhsValue = rhs()
        if let lhs = lhsValue, let rhs = rhsValue {
            XCTAssertEqual(lhs, rhs, file: file, line: line)
        } else if lhsValue != nil || rhsValue != nil {
            let message = "'\(String(describing: lhsValue))' is not equal to '\(String(describing: rhsValue))'"
            XCTFail(message, file: file, line: line)
        }
    }
}

private final class TestObserver {

    init<T: Observable>(_ subject: T) where T.Event == NestedModelCollectionTreeController.Event {
        self.observer = subject.observe({ [weak self] in
            self?.events.append($0)
        })
    }

    fileprivate var events = [NestedModelCollectionTreeController.Event]()
    private var observer: Observer?
}

private final class TestM: Model, ExpressibleByStringLiteral {
    typealias StringLiteralType = String
    init(_ string: String, version: ModelVersion = .unit) {
        self.modelId = string
        self.modelVersion = version
    }
    init(stringLiteral: StringLiteralType) {
        self.modelId = stringLiteral
        self.modelVersion = ModelVersion.unit
    }
    var modelId: ModelId
    var modelVersion: ModelVersion
}

private final class TestMC: NestedModelCollection, ProxyingCollectionEventObservable {
    init(
        id: ModelCollectionId = UUID().uuidString,
        canExpand: @escaping (Model) -> Bool,
        expand: @escaping (Model) -> NestedModelCollection,
        state: ModelCollectionState = .loaded([])
    ) {
        self.collectionId = id
        self.canExpand = canExpand
        self.expand = expand
        self.state = state
    }

    var canExpand: (Model) -> Bool
    var expand: (Model) -> NestedModelCollection
    var collectionId: ModelCollectionId
    var state: ModelCollectionState { didSet { observers.notify(.didChangeState(state)) }}

    func isModelExpandable(_ model: Model) -> Bool {
        return canExpand(model)
    }

    func childModelCollection(_ model: Model) -> NestedModelCollection {
        return expand(model)
    }

    public final var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private final let observers = ObserverList<CollectionEvent>()
}

extension TestMC: ExpressibleByArrayLiteral {
    typealias Element = (String, TestMC?)
    convenience init(arrayLiteral elements: Element...) {
        let canExpand: (Model) -> Bool = { (model) in
            return elements.first(where: { $0.0 == model.modelId })?.1 != nil
        }
        let expand: (Model) -> NestedModelCollection = { (model) in
            return elements.first(where: { $0.0 == model.modelId })?.1 ?? EmptyModelCollection().asNested()
        }
        let models = elements.map { TestM($0.0) }
        self.init(canExpand: canExpand, expand: expand, state: .loaded(models))
    }
}
