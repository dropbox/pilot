import XCTest
@testable import Pilot

class ScoredModelCollectionTests: XCTestCase {

    func testPassthroughSourceCollection() {
        let stub1 = StaticModel(modelId: "1", data: "")
        let stub2 = StaticModel(modelId: "2", data: "")
        let stub3 = StaticModel(modelId: "3", data: "")
        let source = StaticModelCollection(collectionId: "source", initialData: [stub1, stub2, stub3])
        let subject = ScoredModelCollection(source)
        assertModelCollectionState(expected: source.state, actual: subject.state)
    }

    func testSortsByScore() {
        let scorer: (Model) -> Double? = { model in
            return Double(model.modelId)
        }
        let stub1 = StaticModel(modelId: "1", data: "")
        let stub2 = StaticModel(modelId: "2", data: "")
        let stub3 = StaticModel(modelId: "3", data: "")
        let source = StaticModelCollection(collectionId: "source", initialData: [stub1, stub2, stub3])
        let subject = ScoredModelCollection(source)
        subject.scorer = scorer
        let expected = ModelCollectionState.loaded([stub3, stub2, stub1])
        assertModelCollectionState(expected: expected, actual: subject.state)
    }

    func testEnforcesLimit() {
        let scorer: (Model) -> Double? = { model in
            return Double(model.modelId)
        }
        let stub1 = StaticModel(modelId: "1", data: "")
        let stub2 = StaticModel(modelId: "2", data: "")
        let stub3 = StaticModel(modelId: "3", data: "")
        let stub4 = StaticModel(modelId: "3", data: "")
        let source = StaticModelCollection(collectionId: "source", initialData: [stub1, stub2, stub3, stub4])
        let subject = ScoredModelCollection(source)
        subject.sectionLimit = 1
        subject.scorer = scorer
        let expected = ModelCollectionState.loaded([stub2, stub4])
        assertModelCollectionState(expected: expected, actual: subject.state)
    }
}
