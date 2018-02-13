import XCTest
@testable import Pilot

/// Fails test case if `actual` model collection state isn't equivelant to `expected`.
///
/// Checks that the case for both is the same (ex: .loading(*) != .loaded(*)), but if the case is the same then it
/// checks the models have same number of models with the same model ids.
internal func assertModelCollectionState(
    expected: ModelCollectionState,
    actual: ModelCollectionState,
    file: StaticString = #file,
    line: UInt = #line
) {
    if let error = describeModelCollectionStateDiscrepancy(expected: expected, actual: actual) {
        XCTFail(error, file: file, line: line)
    }
}

/// Gives debugging description of why an actual model collection state is different from an expected state. Returns nil
/// if the states are the same.
///
/// Note: Only checks model IDs are consistent doesn't check individual models.
internal func describeModelCollectionStateDiscrepancy(
    expected: ModelCollectionState,
    actual: ModelCollectionState
) -> String? {
    switch expected {
    case .notLoaded:
        if case .notLoaded = actual { return nil }
        return "Expected .notLoaded state, got \(actual)"
    case .error:
        if case .error = actual { return nil }
        return "Expected .error state, got \(actual)"
    case .loading(let expectedSections):
        if case .loading(let actualSections) = actual {
            if expectedSections?.count != actualSections?.count {
                let e = String(describing: expectedSections?.count)
                let a = String(describing: actualSections?.count)
                return "Expected .loading with \(e) sections got \(a)"
            }
            if let expectedSections = expectedSections, let actualSections = actualSections {
                for (e, a) in zip(expectedSections, actualSections) {
                    if (e.map({ $0.modelId }) != a.map({ $0.modelId })) {
                        return "\(e) != \(a)"
                    }
                }
            }
        } else {
            return "Expected .loading(\(String(describing: expectedSections))). Actual: \(actual)"
        }
    case .loaded(let expectedSections):
        if case .loaded(let actualSections) = actual {
            if expectedSections.count != actualSections.count {
                return "Expected .loaded with \(expectedSections.count) sections got \(actualSections.count)"
            }
            for (e, a) in zip(expectedSections, actualSections) {
                if (e.map({ $0.modelId }) != a.map({ $0.modelId })) {
                    return "\(e) != \(a)"
                }
            }
        } else {
            return "Expected .loaded with \(expectedSections)). Actual: \(actual)"
        }
    }
    return nil
}

/// Returns true if `actual` ModelCollectionState matches `expected`.
internal func validateModelCollectionState(
    expected: ModelCollectionState,
    actual: ModelCollectionState
) -> Bool {
    return describeModelCollectionStateDiscrepancy(expected: expected, actual: actual) == nil
}
