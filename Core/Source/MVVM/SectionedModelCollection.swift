import Foundation

public protocol SectionedModelCollection: class {
    var sections: [[Model]] { get }
}

public extension SectionedModelCollection where Self : ModelCollection {
    public var sections: [[Model]] {
        return [self.state.models]
    }
}

public extension ModelCollection {
    public func withSections() -> SectionedModelCollection {
        if let sectioned = self as? SectionedModelCollection {
            return sectioned
        }
        return StaticSectionedModelCollection(self)
    }
}

extension SectionedModelCollection {
    /// Returns a typed cast of the model value at the given index path, or nil if the model is not of that type or
    /// the index path is out of bounds.
    public func atIndexPath<T>(_ indexPath: IndexPath) -> T? {
        if case sections.indices = indexPath.modelSection {
            let section = sections[indexPath.modelSection]
            if case section.indices = indexPath.modelItem {
                if let typed = section[indexPath.modelItem] as? T {
                    return typed
                }
            }
        }
        return nil
    }

    /// Returns a typed cast of the model value at the given index path, or nil if the model is not of that type or
    /// the index path is out of bounds.
    public func atModelPath<T>(_ modelPath: ModelPath) -> T? {
        if case sections.indices = modelPath.sectionIndex {
            let section = sections[modelPath.sectionIndex]
            if case section.indices = modelPath.itemIndex {
                if let typed = section[modelPath.itemIndex] as? T {
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
        for (sectionIdx, section) in self.sections.enumerated() {
            if let itemIdx = section.index(where: matching) {
                return IndexPath(forModelItem: itemIdx, inSection: sectionIdx)
            }
        }
        return nil
    }
}

/// Internal only class used to get around the swift inability to add conformance of a protocol to a protocol via an
/// extension.
internal final class StaticSectionedModelCollection: ModelCollection, SectionedModelCollection {
    internal init(_ modelCollection: ModelCollection) {
        self.represented = modelCollection
    }

    // MARK: ModelCollection

    internal func addObserver(_ observer: @escaping  CollectionEventObserver) -> CollectionEventObserverToken {
        return represented.addObserver(observer)
    }

    internal func removeObserver(with token: CollectionEventObserverToken) {
        represented.removeObserver(with: token)
    }

    internal var collectionId: ModelCollectionId { return represented.collectionId }
    internal var state: ModelCollectionState { return represented.state }

    // MARK: Private

    private let represented: ModelCollection
}
