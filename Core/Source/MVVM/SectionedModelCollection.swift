import Foundation

/// Specialization of a `ModelCollection` that provides support for sections — typically used when mapping to
/// table and collection views, which support sections.
public protocol SectionedModelCollection: ModelCollection {
    /// An array of `ModelCollectionState` where each item represents a section. This is a higher-fidelity view of
    /// `ModelCollection.state` that divides the same set of `Model` objects into sections that each support their own
    /// state.
    ///
    /// Implementations would likely use `sectionedState.flattenedState()` for an implementation of
    /// `ModelCollection.state`, as it provides a reasonable default mapping from multiple section states to a single
    /// state representing the entire collection.
    var sectionedState: [ModelCollectionState] { get }
}

public extension ModelCollection {

    /// If the target type is already a `SectionedModelCollection`, this method does nothing except downcast. Otherwise,
    /// returns a `SectionedModelCollection` with the target `ModelCollection` as the only section.
    public func asSectioned() -> SectionedModelCollection {
        if let sectioned = self as? SectionedModelCollection {
            return sectioned
        }
        return SingleSectionedModelCollection(self)
    }
}

public struct ModelCollectionStateFlattenError: Error {
    public var errors: [Error]
}

public extension Sequence where Iterator.Element == ModelCollectionState {

    /// Common implementation to transform `[ModelCollectionState] -> ModelCollectionState`. Typically used by
    /// `SectionedModelCollection` implementations when they need to return a single representative
    /// `ModelCollectionState`.
    public func flattenedState() -> ModelCollectionState {
        var count = 0
        var consolidatedModels: [Model] = []
        var reducedStates = ModelCollectionStateReduction()
        for substate in self {
            count += 1
            consolidatedModels += substate.models

            switch substate {
            case .notLoaded:
                reducedStates.notLoadedCount += 1
            case .loaded:
                reducedStates.loadedCount += 1
            case .error(let error):
                reducedStates.errorArray.append(error)
            case .loading(let models):
                if models == nil {
                    reducedStates.loadingCount += 1
                } else {
                    reducedStates.loadingMoreCount += 1
                }
            }
        }

        if !reducedStates.errorArray.isEmpty {
            let error = ModelCollectionStateFlattenError(errors: reducedStates.errorArray)
            return .error(error)
        } else if reducedStates.notLoadedCount == count {
            return .notLoaded
        } else if reducedStates.loadedCount == count {
            return .loaded(consolidatedModels)
        } else if reducedStates.loadingCount + reducedStates.notLoadedCount == count {
            return .loading(nil)
        } else {
            return .loading(consolidatedModels)
        }
    }
}

public extension Sequence where Iterator.Element == [Model] {
    /// Convenience method for returning a `[ModelCollectionState]` from a two-dimentional `Model` array.
    public func asSectionedState(loading: Bool = false) -> [ModelCollectionState] {
        return self.map { loading ? .loading($0) : .loaded($0) }
    }
}

extension SectionedModelCollection {

    /// Returns sections of `Model` items.
    public var sections: [[Model]] {
        return sectionedState.map { $0.models }
    }

    /// Returns a typed cast of the model value at the given index path, or nil if the model is not of that type or
    /// the index path is out of bounds.
    public func atIndexPath<T>(_ indexPath: IndexPath) -> T? {
        if case sectionedState.indices = indexPath.modelSection {
            let section = sectionedState[indexPath.modelSection]
            if case section.models.indices = indexPath.modelItem {
                if let typed = section.models[indexPath.modelItem] as? T {
                    return typed
                }
            }
        }
        return nil
    }

    /// Returns a typed cast of the model value at the given index path, or nil if the model is not of that type or
    /// the index path is out of bounds.
    public func atModelPath<T>(_ modelPath: ModelPath) -> T? {
        if case sectionedState.indices = modelPath.sectionIndex {
            let section = sectionedState[modelPath.sectionIndex]
            if case section.models.indices = modelPath.itemIndex {
                if let typed = section.models[modelPath.itemIndex] as? T {
                    return typed
                }
            }
        }
        return nil
    }

    /// Returns the index path for the given model id, if present.
    /// - Complexity: O(n)
    public func indexPath(forModelId modelId: ModelId) -> IndexPath? {
        return indexPathOf() { $0.modelId == modelId }
    }

    /// Returns the index path for first item matching the provided closure
    /// - Complexity: O(n)
    public func indexPathOf(matching: (Model) -> Bool) -> IndexPath? {
        for (sectionIdx, section) in self.sectionedState.enumerated() {
            if let itemIdx = section.models.index(where: matching) {
                return IndexPath(forModelItem: itemIdx, inSection: sectionIdx)
            }
        }
        return nil
    }
}

/// Internal only class used for wrapping a non-sectioned `ModelCollection` with `SectionedModelCollection` support.
internal final class SingleSectionedModelCollection: SectionedModelCollection {
    internal init(_ modelCollection: ModelCollection) {
        self.represented = modelCollection
    }

    // MARK: SectionedModelCollection

    internal var sectionedState: [ModelCollectionState] {
        return [represented.state]
    }

    // MARK: ModelCollection

    internal func observeValues(_ observer: @escaping (CollectionEvent) -> Void) -> Subscription {
        return represented.observeValues(observer)
    }

    internal var collectionId: ModelCollectionId { return represented.collectionId }
    internal var state: ModelCollectionState { return represented.state }

    // MARK: Private

    private let represented: ModelCollection
}

/// Helper struct for flattening `SectionedModelCollection` state.
private struct ModelCollectionStateReduction {
    var notLoadedCount = 0
    var loadingCount = 0
    var loadedCount = 0
    var loadingMoreCount = 0
    var errorArray: [Error] = []
}
