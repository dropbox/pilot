@testable import Pilot
import XCTest

private func mp(_ sectionIndex: Int, _ itemIndex: Int) -> ModelPath {
    return ModelPath(sectionIndex: sectionIndex, itemIndex: itemIndex)
}

class DiffEngineTests: XCTestCase {
    var de = DiffEngine()

    override func setUp() {
        super.setUp()
        de = DiffEngine()
    }

    func assertUpdates(_ expected: CollectionEventUpdates, _ newState: [[Model]], file: String = #file, line: UInt = #line) {
        let actual = de.update(newState)

        func compare1<T: Equatable>(_ name: String, _ e: T, _ a: T) {
            if e != a {
                self.recordFailure(withDescription: name + " differs. actual: \(a) expected: \(e)", inFile: file, atLine: Int(line), expected: true)
            }
        }
        func compare<T: Equatable>(_ name: String, _ e: [T], _ a: [T]) {
            if e != a {
                self.recordFailure(withDescription: name + " differs. actual: \(a) expected: \(e)", inFile: file, atLine: Int(line), expected: true)
            }
        }

        compare("removedSections", expected.removedSections, actual.removedSections)
        compare("addedSections", expected.addedSections, actual.addedSections)

        compare("removedModelPaths", expected.removedModelPaths, actual.removedModelPaths)
        compare("addedModelPaths", expected.addedModelPaths, actual.addedModelPaths)
        compare("movedModelPaths", expected.movedModelPaths, actual.movedModelPaths)
        compare("updatedModelPaths", expected.updatedModelPaths, actual.updatedModelPaths)

        compare1("containsFirstAddInSection", expected.containsFirstAddInSection, actual.containsFirstAddInSection)
        compare1("containsLastRemoveInSection", expected.containsLastRemoveInSection, actual.containsLastRemoveInSection)
        compare("removedModelIds", expected.removedModelIds, actual.removedModelIds.sorted())
    }

    func test_no_difference() {
        assertUpdates(CollectionEventUpdates(), [])
        assertUpdates(CollectionEventUpdates(), [])
    }

    func test_add_and_remove_sections() {
        var expected1 = CollectionEventUpdates()
        expected1.addedSections = [0, 1]
        assertUpdates(expected1, [[], []])

        var expected2 = CollectionEventUpdates()
        expected2.removedSections = [0, 1]
        assertUpdates(expected2, [])
    }

    func test_add_and_remove_section_with_item() {
        var expected1 = CollectionEventUpdates()
        expected1.addedSections = [0]
        expected1.addedModelPaths = [mp(0, 0)]
        expected1.containsFirstAddInSection = true
        assertUpdates(expected1, [[TM.A]])

        var expected2 = CollectionEventUpdates()
        expected2.removedSections = [0]
        expected2.removedModelIds = ["A"]
        expected1.containsLastRemoveInSection = true
        assertUpdates(expected2, [])
    }

    func test_add_and_remove_item() {
        let _ = de.update([[]])

        var expected1 = CollectionEventUpdates()
        expected1.addedModelPaths = [mp(0, 0)]
        expected1.containsFirstAddInSection = true
        assertUpdates(expected1, [[TM.A]])

        var expected2 = CollectionEventUpdates()
        expected2.removedModelPaths = [mp(0, 0)]
        expected2.removedModelIds = ["A"]
        expected2.containsLastRemoveInSection = true
        assertUpdates(expected2, [[]])
    }

    func test_replace_duplicate_model_with_different_model() {
        let _ = de.update([[TM.A, TM.A]])

        var expected = CollectionEventUpdates()
        expected.removedModelPaths = [mp(0, 1)]
        expected.addedModelPaths = [mp(0, 0)]
        assertUpdates(expected, [[TM.B, TM.A]])
    }

    func test_delete_one_duplicate() {
        let _ = de.update([[TM.A, TM.A]])

        var expected = CollectionEventUpdates()
        expected.removedModelPaths = [mp(0, 1)]
        assertUpdates(expected, [[TM.A]])
    }

    func test_update_item() {
        let _ = de.update([[TM.A]])

        var expected = CollectionEventUpdates()
        expected.updatedModelPaths = [mp(0, 0)]
        assertUpdates(expected, [[TM.A_1]])
    }

    func test_add_item_twice() {
        let _ = de.update([[TM.A]])

        var expected = CollectionEventUpdates()
        expected.addedModelPaths = [mp(0, 1)]
        assertUpdates(expected, [[TM.A, TM.A]])
    }

    func test_move_items() {
        let _ = de.update([[TM.A, TM.B]])

        var expected = CollectionEventUpdates()
        expected.movedModelPaths = [
            MovedModel(from: mp(0, 1), to: mp(0, 0)),
        ]
        assertUpdates(expected, [[TM.B, TM.A]])
    }

    func test_move_and_update_1() {
        let _ = de.update([[TM.A, TM.B]])

        var expected = CollectionEventUpdates()
        expected.movedModelPaths = [
            MovedModel(from: mp(0, 1), to: mp(0, 0)),
        ]
        expected.updatedModelPaths = [mp(0, 1)]
        assertUpdates(expected, [[TM.B, TM.A_1]])
    }

    func test_move_and_update_0() {
        let _ = de.update([[TM.A, TM.B]])

        var expected = CollectionEventUpdates()
        expected.movedModelPaths = [
            MovedModel(from: mp(0, 1), to: mp(0, 0)),
        ]
        expected.updatedModelPaths = [mp(0, 0)]
        assertUpdates(expected, [[TM.B_1, TM.A]])
    }

    func test_delete_item_at_start_of_duplicates() {
        let _ = de.update([[TM.A, TM.B, TM.B]])

        var expected = CollectionEventUpdates()
        expected.removedModelPaths = [mp(0, 0)]
        expected.removedModelIds = ["A"]
        assertUpdates(expected, [[TM.B, TM.B]])
    }

    func test_dont_move_items_from_deleted_section() {
        let _ = de.update([[], [TM.A, TM.B]])

        var expected = CollectionEventUpdates()
        expected.removedSections = [1]
        expected.addedModelPaths = [mp(0, 0), mp(0, 1)]
        expected.containsFirstAddInSection = true
        assertUpdates(expected, [[TM.A, TM.B]])
    }

    func test_inserts_are_relative_to_delete_indices() {
        let _ = de.update([[TM.A, TM.B, TM.C, TM.D, TM.E]])

        var expected = CollectionEventUpdates()
        expected.removedModelPaths = [mp(0, 0), mp(0, 4)]
        expected.addedModelPaths = [mp(0, 1), mp(0, 3)]
        expected.removedModelIds = ["A", "E"]
        assertUpdates(expected, [[TM.B, TM.F, TM.C, TM.G, TM.D]])
    }

    func test_move_from_previous_section() {
        let _ = de.update([[TM.A], []])

        var expected = CollectionEventUpdates()

        expected.movedModelPaths = [MovedModel(from: mp(0, 0), to: mp(1, 0))]
        expected.containsFirstAddInSection = true
        expected.containsLastRemoveInSection = true
        assertUpdates(expected, [[], [TM.A]])

        expected.movedModelPaths = [MovedModel(from: mp(1, 0), to: mp(0, 0))]
        expected.containsFirstAddInSection = true
        expected.containsLastRemoveInSection = true
        assertUpdates(expected, [[TM.A], []])
    }

    func test_two_moves() {
        let _ = de.update([[], [TM.A], [TM.B]])

        var expected = CollectionEventUpdates()
        expected.movedModelPaths = [
            MovedModel(from: mp(2, 0), to: mp(0, 0)),
            MovedModel(from: mp(1, 0), to: mp(2, 0)),
        ]
        expected.containsFirstAddInSection = true
        expected.containsLastRemoveInSection = true
        assertUpdates(expected, [[TM.B], [], [TM.A]])
    }

    func test_two_moves_2() {
        let _ = de.update([[], [TM.B], [TM.A]])

        var expected = CollectionEventUpdates()
        expected.movedModelPaths = [
            MovedModel(from: mp(1, 0), to: mp(0, 0)),
        ]
        expected.containsFirstAddInSection = true
        expected.containsLastRemoveInSection = true
        assertUpdates(expected, [[TM.B], [], [TM.A]])
    }

    func test_consume_duplicate_model() {
        let loading = TM(id: "loading", version: 1)
        let _ = de.update([[TM.A], [loading], [loading]])

        var expected = CollectionEventUpdates()
        expected.addedModelPaths = [mp(1, 0), mp(2, 0)]
        expected.removedModelPaths = [mp(0, 0), mp(2, 0)]
        expected.movedModelPaths = [MovedModel(from: mp(1, 0), to: mp(0, 0))]
        expected.removedModelIds = ["A"]
        assertUpdates(expected, [[loading], [TM.B], [TM.C]])
    }
}
