import XCTest
@testable import Pilot

private struct StubError: Error {}

class MultiplexModelCollectionTests: XCTestCase {

    func testPassthroughLoadedModels() {
        let first = StaticModel(modelId: "0.0", data: "")
        let second = StaticModel(modelId: "1.0", data: "")

        let subject = ComposedModelCollection.multiplexing([
            StaticModelCollection([first]),
            StaticModelCollection([second]),
            ])
        let expected: ModelCollectionState = .loaded([first, second])
        assertModelCollectionState(expected: expected, actual: subject.state)
    }

    func testPropegatesLoadingState() {
        let firstSubCollection = SimpleModelCollection()
        let secondSubCollection = SimpleModelCollection()
        let subject = ComposedModelCollection.multiplexing([firstSubCollection, secondSubCollection])
        assertModelCollectionState(expected: .notLoaded, actual: subject.state)
        firstSubCollection.onNext(.loading(nil))
        assertModelCollectionState(expected: .loading(nil), actual: subject.state)
    }

    func testPropegatesErrorState() {
        let firstSubCollection = SimpleModelCollection()
        let secondSubCollection = SimpleModelCollection()
        let subject = ComposedModelCollection.multiplexing([firstSubCollection, secondSubCollection])
        firstSubCollection.onNext(.loaded([]))
        secondSubCollection.onNext(.error(StubError()))
        assertModelCollectionState(expected: .error(StubError()), actual: subject.state)
    }

    func testInsertsEmptySectionsForNotLoadedSections() {
        let firstSubCollection = SimpleModelCollection()
        let secondSubCollection = SimpleModelCollection()
        let thirdSubCollection = SimpleModelCollection()
        let subject = ComposedModelCollection.multiplexing([firstSubCollection, secondSubCollection, thirdSubCollection])
        firstSubCollection.onNext(.loaded([StaticModel(modelId: "0", data: "")]))
        secondSubCollection.onNext(.loading(nil))
        thirdSubCollection.onNext(.loaded([StaticModel(modelId: "1", data: "")]))
        let expected: ModelCollectionState = .loading([
            StaticModel(modelId: "0", data: ""),
            StaticModel(modelId: "1", data: "")
            ])
        assertModelCollectionState(expected: expected, actual: subject.state)
    }

    func testPropegatesLoadedState() {
        let firstSubCollection = SimpleModelCollection()
        let secondSubCollection = SimpleModelCollection()
        let subject = ComposedModelCollection.multiplexing([firstSubCollection, secondSubCollection])
        firstSubCollection.onNext(.loaded([StaticModel(modelId: "0", data: "")]))
        secondSubCollection.onNext(.loaded([StaticModel(modelId: "1", data: "")]))
        let expected: ModelCollectionState = .loaded([
            StaticModel(modelId: "0", data: ""),
            StaticModel(modelId: "1", data: "")
            ])
        assertModelCollectionState(expected: expected, actual: subject.state)
    }
}
