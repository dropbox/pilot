@testable import Pilot
import XCTest

private typealias SModel = StaticModel<String>

private let testData: [[SModel]] = [
    [
        StaticModel(modelId: "454", data: "Archon"),
        StaticModel(modelId: "455", data: "Destiny"),
        StaticModel(modelId: "456", data: "Nine Fives"),
        StaticModel(modelId: "457", data: "Focus"),
    ],
    [
        StaticModel(modelId: "354", data: "R.I.C.E."),
        StaticModel(modelId: "355", data: "Chai Time"),
        StaticModel(modelId: "356", data: "Flavor of the Day"),
        StaticModel(modelId: "357", data: "Scooter's"),
    ],
    [
        StaticModel(modelId: "254", data: "Bikeshed"),
        StaticModel(modelId: "255", data: "Dropboat"),
        StaticModel(modelId: "256", data: "Emperor Norton Bridge"),
        StaticModel(modelId: "257", data: "Client Someday"),
    ],
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
        XCTAssertEqual(collection.totalItemCount, 3)
    }

    // MARK: Test Helpers

    fileprivate func createFilteredModelCollection(
        _ data: [[SModel]] = testData,
        kind: FilteredModelCollection.FilterKind = .sync,
        filter: ModelFilter? = nil
    ) -> FilteredModelCollection {

        let source = StaticModelCollection(collectionId: "source", initialData: data)
        return FilteredModelCollection(sourceCollection: source, kind: kind, filter: filter)
    }

    fileprivate var filteredModelCollection: FilteredModelCollection!
}
