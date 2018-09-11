@testable import Pilot
import XCTest

private typealias SModel = StaticModel<String>

private let testData: [SModel] = [
        StaticModel(modelId: "454", data: "Archon"),
        StaticModel(modelId: "455", data: "Destiny"),
        StaticModel(modelId: "456", data: "Nine Fives"),
        StaticModel(modelId: "457", data: "Focus"),
        StaticModel(modelId: "354", data: "R.I.C.E."),
        StaticModel(modelId: "355", data: "Chai Time"),
        StaticModel(modelId: "356", data: "Flavor of the Day"),
        StaticModel(modelId: "357", data: "Scooter's"),
        StaticModel(modelId: "254", data: "Bikeshed"),
        StaticModel(modelId: "255", data: "Dropboat"),
        StaticModel(modelId: "256", data: "Emperor Norton Bridge"),
        StaticModel(modelId: "257", data: "Client Someday"),
]

class FilteredModelCollectionTests: XCTestCase {

    // MARK: XCTestCase

    override func setUp() {
        super.setUp()
        filteredModelCollection = createFilteredModelCollection()
    }

    override func tearDown() {
        filteredModelCollection = nil
        super.tearDown()
    }

    // MARK: Specs

    func testBasicFilterAtInitialization() {
        let collection = createFilteredModelCollection(testData) { model in
            return ["454", "355", "257"].contains(model.modelId)
        }
        let expected = ModelCollectionState.loaded([
            StaticModel(modelId: "454", data: "Archon"),
            StaticModel(modelId: "355", data: "Chai Time"),
            StaticModel(modelId: "257", data: "Client Someday")
        ])
        assertModelCollectionState(expected: expected, actual: collection.state)
    }

    func testShouldEnforceLimit() {
        let collection = createFilteredModelCollection(testData) { model in
            return model.modelId.hasPrefix("4")
        }
        var expected = ModelCollectionState.loaded([
            StaticModel(modelId: "454", data: "Archon"),
            StaticModel(modelId: "455", data: "Destiny"),
            StaticModel(modelId: "456", data: "Nine Fives"),
            StaticModel(modelId: "457", data: "Focus")
        ])
        assertModelCollectionState(expected: expected, actual: collection.state)
        collection.limit = 2
        expected = ModelCollectionState.loaded([
            StaticModel(modelId: "454", data: "Archon"),
            StaticModel(modelId: "455", data: "Destiny"),
        ])
        assertModelCollectionState(expected: expected, actual: collection.state)
    }

    func testUpdateFilter() {
        let collection = createFilteredModelCollection(testData) { model in
            return model.modelId == "454"
        }
        var expected = ModelCollectionState.loaded([StaticModel(modelId: "454", data: "Archon")])
        assertModelCollectionState(expected: expected, actual: collection.state)
        collection.filter = { _ in return true }
        expected = ModelCollectionState.loaded(testData)
        assertModelCollectionState(expected: expected, actual: collection.state)
    }

    func testAsync() {
        let expectation = self.expectation(description: "filter")
        let subject = createFilteredModelCollection(testData, kind: .async(queue: .background)) { _ in
            return false
        }
        XCTAssert(subject.state.isLoading)
        let expected = ModelCollectionState.loaded([])
        let token = subject.observeValues { (event) in
            guard case .didChangeState(let state) = event else { return }
            if validateModelCollectionState(expected: expected, actual: state) {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 2) { (err) in
            if let err = err {
                let message = describeModelCollectionStateDiscrepancy(expected: expected, actual: subject.state)
                XCTFail(message ?? err.localizedDescription)
            }
            _ = token
        }
    }

    func testDiscardsStaleAsyncResults() {
        var hasSlept = false
        let subject = createFilteredModelCollection(testData, kind: .async(queue: .background)) { _ in
            if !hasSlept {
                Thread.sleep(forTimeInterval: 0.25)
                hasSlept = true
            }
            return true
        }
        subject.filter = { _ in return false }
        XCTAssert(subject.state.isLoading)
        let expected = ModelCollectionState.loaded([])
        let expectation1 = self.expectation(description: "correctFilter")
        // We expect this expectation to timeout, since the initial filter will not update the collection.
        let expectation2 = self.expectation(description: "Stale filter results shouldn't be applied!")
        expectation2.isInverted = true
        var correctResultsLoaded = false
        let token = subject.observeValues { (event) in
            guard case .didChangeState(let state) = event else { return }
            if validateModelCollectionState(expected: expected, actual: state) {
                expectation1.fulfill()
                correctResultsLoaded = true
            } else if correctResultsLoaded {
                if !state.isEmpty {
                    expectation2.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 2) { _ in
            _ = token
        }
        assertModelCollectionState(expected: .loaded([]), actual: subject.state)
    }

    func testUpdateSource() {
        let source = SimpleModelCollection()
        source.onNext(.loaded([]))
        let subject = FilteredModelCollection(sourceCollection: source, filter: { $0.modelId.hasSuffix("4") })
        assertModelCollectionState(expected: .loaded([]), actual: subject.state)
        let archon = StaticModel(modelId: "454", data: "Archon")
        let destiny = StaticModel(modelId: "455", data: "Destiny")
        let models = [archon, destiny]
        source.onNext(.loading(models))
        assertModelCollectionState(expected: .loading([archon]), actual: subject.state)
        source.onNext(.loaded(models))
        assertModelCollectionState(expected: .loaded([archon]), actual: subject.state)
    }

    func testReRun() {
        var value = true
        let subject = createFilteredModelCollection(testData) { _ in
            return value
        }
        assertModelCollectionState(expected: .loaded(testData), actual: subject.state)
        value = false
        subject.rerunFilter()
        assertModelCollectionState(expected: .loaded([]), actual: subject.state)
    }

    // MARK: Test Helpers

    private func createFilteredModelCollection(
        _ data: [SModel] = testData,
        kind: FilteredModelCollection.FilterKind = .sync,
        filter: ModelFilter? = nil
    ) -> FilteredModelCollection {

        let source = StaticModelCollection(collectionId: "source", initialData: data)
        return FilteredModelCollection(sourceCollection: source, kind: kind, filter: filter)
    }

    private var filteredModelCollection: FilteredModelCollection!
}
