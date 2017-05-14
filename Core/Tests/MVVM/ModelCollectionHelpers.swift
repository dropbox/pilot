import XCTest
@testable import Pilot

/// Fails test case if `actual` model collection state isn't equivelant to `expected`.
///
/// Checks that the case for both is the same (ex: .loading(*) != .loaded(*)), but if the case is the same then it
/// checks the sections have same number of models with the same model ids.
internal func assertModelCollectionState(
    expected: ModelCollectionState,
    actual: ModelCollectionState,
    file: StaticString = #file,
    line: UInt = #line
) {
    switch expected {
    case .notLoaded:
        if case .notLoaded = actual { return }
        XCTFail("Expected .notLoaded state, got \(actual)", file: file, line: line)
    case .error:
        if case .error = actual { return }
        XCTFail("Expected .error state, got \(actual)", file: file, line: line)
    case .loading(let expectedSections):
        if case .loading(let actualSections) = actual {
            XCTAssertEqual(
                expectedSections?.count,
                actualSections?.count,
                "Expected .loading with \(expectedSections?.count ?? 0) sections, got \(actualSections?.count ?? 0)")
            if let expectedSections = expectedSections, let actualSections = actualSections {
                XCTAssertEqual(expectedSections.map({ $0.modelId }), actualSections.map({ $0.modelId }))
            }
        } else {
            XCTFail("Expected .loading(\(String(describing: expectedSections)))\ngot: \(actual)", file: file, line: line)
        }
    case .loaded(let expectedSections):
        if case .loaded(let actualSections) = actual {
            XCTAssertEqual(
                expectedSections.count,
                actualSections.count,
                "Expected .loaded with \(expectedSections.count) sections got \(actualSections.count)")
            XCTAssertEqual(expectedSections.map({ $0.modelId }), actualSections.map({ $0.modelId }))
        } else {
            XCTFail("Expected .loaded with \(expectedSections))\ngot: \(actual)", file: file, line: line)
        }
    }
}
