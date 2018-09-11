@testable import Pilot
import XCTest

private typealias Model = StaticModel<String>

private let testData: [Model] = [
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

class MappedModelCollectionTests: XCTestCase {

    // MARK: XCTestCase

    override func setUp() {
        super.setUp()
        modelCollection = createFilteredModelCollection()
    }

    override func tearDown() {
        modelCollection = nil
        super.tearDown()
    }

    // MARK: Specs

    func testPerformsMapWhenUpdated() {
        let expectation = self.expectation(description: "Should call reload")
        let observer = modelCollection.observeValues { event in
            if case .loaded = self.modelCollection.state {
                expectation.fulfill()
            }
        }
        modelCollection.transform = { model in
            let model: Model = model.typedModel()
            return Model(modelId: model.modelId, data: model.data.uppercased())
        }
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                print("ERROR: \(error)")
            }
            observer.unsubscribe()
        }
        zip(testData, modelCollection.models).forEach { inModel, outputModel in
            let out: Model = outputModel.typedModel()
            XCTAssertEqual(inModel.data.uppercased(), out.data)
        }
    }

    // MARK: Helpers

    private func createFilteredModelCollection(_ data: [Model] = testData) -> MappedModelCollection {
        let source = StaticModelCollection(collectionId: "source", initialData: data)
        let modelCollection = MappedModelCollection(sourceCollection: source)
        modelCollection.transform = { model in return model }
        let expectation = self.expectation(description: "should call observers with reload after setup")
        let initialReloadObserver = modelCollection.observeValues { [modelCollection] event in
            if case .loaded = modelCollection.state {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
        if case .loaded = modelCollection.state {
            initialReloadObserver.unsubscribe()
        } else {
            XCTFail("Filtered model not loaded.")
        }
        return modelCollection
    }

    private var modelCollection: MappedModelCollection!
}
