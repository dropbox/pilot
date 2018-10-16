import XCTest
@testable import Pilot

class SortedModelCollectionTests: XCTestCase {
//    func testSortCollection() {
//        let stub1 = StaticModel(modelId: "3", data: "")
//        let stub2 = StaticModel(modelId: "2", data: "")
//        let stub3 = StaticModel(modelId: "1", data: "")
//
//        let source = SimpleModelCollection()
//        source.onNext(.loaded([stub1, stub2, stub3]))
//        let subject = SortedModelCollection(source)
//        subject.comparator = { m1, m2 in
//            return m1.modelId < m2.modelId
//        }
//
//        let expected = ModelCollectionState.loaded([stub3, stub2, stub1])
//        assertModelCollectionState(expected: expected, actual: subject.state)
//
//        // Loading more data should update the source model.
//        let stub4 = StaticModel(modelId: "0", data: "")
//        source.onNext(.loaded([stub1, stub2, stub3, stub4]))
//        let expected2 = ModelCollectionState.loaded([stub4, stub3, stub2, stub1])
//        assertModelCollectionState(expected: expected2, actual: subject.state)
//    }
}
