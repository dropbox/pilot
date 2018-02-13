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
    case .loading(let expectedModels):
        if case .loading(let actualModels) = actual {
            if expectedModels?.count != actualModels?.count {
                let e = String(describing: expectedModels?.count)
                let a = String(describing: actualModels?.count)
                return "Expected .loading with \(e) models got \(a)"
            }
            if let expectedModels = expectedModels, let actualModels = actualModels {
                for (e, a) in zip(expectedModels, actualModels) {
                    if e.modelId != a.modelId {
                        return "\(e) != \(a)"
                    }
                }
            }
        } else {
            return "Expected .loading(\(String(describing: expectedModels))). Actual: \(actual)"
        }
    case .loaded(let expectedModels):
        if case .loaded(let actualModels) = actual {
            if expectedModels.count != actualModels.count {
                return "Expected .loaded with \(expectedModels.count) models got \(actualModels.count)"
            }
            for (e, a) in zip(expectedModels, actualModels) {
                if e.modelId != a.modelId {
                    return "\(e) != \(a)"
                }
            }
        } else {
            return "Expected .loaded with \(expectedModels)). Actual: \(actual)"
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
