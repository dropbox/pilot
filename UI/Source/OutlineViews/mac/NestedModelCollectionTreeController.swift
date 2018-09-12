import Foundation
import Pilot
#if canImport(RxSwift)
import RxSwift
#endif

/// Responsible for managing a lazily evaluated tree of nested model collections.
///
/// Intended to provide a wrapper around nested model collections for the OutlineTableViewModelDataSource and interface
/// is heavily optimized for that usecase (ie isExpandable and countOfChildNodes) as opposed to a general tree interface
/// and is designd to be addressed by IndexPaths that can be used as pointers back into specific models.
///
/// NOTE: NestedModelCollectionTreeController is considered == whenever the indexPath and ModelCollection ids are ==
internal final class NestedModelCollectionTreeController: ProxyingObservable {

    /// Opaque reference to a location of a node in the tree. NSObject subclass so this object can be used as the
    /// item in all NSOutlineView/NSOutlineViewDataSource APIs.
    internal class TreePath: NSObject {
        override init() {
            self.components = []
            super.init()
        }

        fileprivate init(components: [ModelId]) {
            self.components = components
            super.init()
        }

        // MARK: Public

        public var depth: Int {
            return components.count
        }

        // MARK: Equatable

        static func ==(lhs: TreePath, rhs: TreePath) -> Bool {
            return lhs.components == rhs.components
        }

        // MARK: NSObject

        override func isEqual(_ object: Any?) -> Bool {
            if let other = object as? TreePath {
                return other.components == components
            }
            return false
        }

        override var hash: Int {
            var result = 0
            for component in components { result = result ^ component.hash }
            return result
        }

        // MARK: fileprivate

        func dropFirst() -> TreePath {
            return TreePath(components: Array(components.dropFirst()))
        }

        func dropLast() -> TreePath {
            return TreePath(components: Array(components.dropLast()))
        }

        func appending(_ modelId: ModelId) -> TreePath {
            return TreePath(components: components + [modelId])
        }

        fileprivate var components: [ModelId]
    }

    // MARK: Initialization

    internal convenience init(modelCollection: NestedModelCollection) {
        self.init(modelCollection: modelCollection, modelId: nil, parent: nil)
    }

    private init(
        modelCollection: NestedModelCollection = EmptyModelCollection().asNested(),
        modelId: ModelId? = nil,
        parent: NestedModelCollectionTreeController? = nil
    ) {
        self.parent = parent
        self.modelId = modelId
        self.modelCollection = modelCollection
        if let parent = parent {
            self.observers = parent.observers
        } else {
            self.observers = ObserverList<TreeControllerEvent>()
        }
        // Update diff engine state up to current state of ModelCollection so future calls to .update get correct diffs.
        _ = diffEngine.update([modelCollection.models])
        recreateModelCollectionCache()
        self.modelCollectionObserver = modelCollection.observeValues { [weak self] (event) in
            self?.handleCollectionEvent(event)
        }
    }

    // MARK: Internal API

    internal func isExpandable(_ path: TreePath) -> Bool {
        let model = modelAtPath(path)
        let containingNode = findOrCreateNode(path.dropLast())
        return containingNode.modelCollection.canExpand(model)
    }

    internal func numberOfChildren(_ path: TreePath?) -> Int {
        return findOrCreateNode(path ?? TreePath()).modelCollection.models.count
    }

    internal func modelAtPath(_ path: TreePath) -> Model {
        guard !path.components.isEmpty else { Log.fatal(message: "Empty path passed to modelAtIndexPath()") }
        let containingNode = findOrCreateNode(path.dropLast())
        guard let model = containingNode.modelCollectionCache[path.components.last!]?.1 else {
            Log.fatal(message: "modelAtPath requested for unknown 'path' \(path)")
        }
        return model
    }

    internal func modelAtIndexPath(_ indexPath: IndexPath) -> Model {
        return modelAtPath(treePathFromIndexPath(indexPath))
    }

    internal func treePathFromIndexPath(_ path: IndexPath) -> TreePath {
        var path = path
        var result = TreePath()
        var node = self
        while !path.isEmpty {
            let nextIndex = path.removeFirst()
            let nextModelId = node.modelCollection.models[nextIndex].modelId
            result = result.appending(nextModelId)
            if !path.isEmpty {
                node = node.findOrCreateNode(TreePath(components: [nextModelId]))
            }
        }
        return result
    }

    internal func pathForChild(_ index: Int, of parent: TreePath?) -> TreePath {
        let parentPath = parent ?? TreePath()
        let modelId = modelIdForChild(path: parentPath, child: index)
        return parentPath.appending(modelId)
    }

    internal func modelIdForChild(path: TreePath?, child index: Int) -> ModelId {
        return findOrCreateNode(path ?? TreePath()).modelCollection.models[index].modelId
    }

    // MARK: Equatable

    static func ==(lhs: NestedModelCollectionTreeController, rhs: NestedModelCollectionTreeController) -> Bool {
        return lhs.indexPath == rhs.indexPath && lhs.modelCollection.collectionId == rhs.modelCollection.collectionId
    }

    // MARK: ObservableType

    /// Description of mutations to model collection tree.
    ///
    /// IndexPaths are consistent when interpreted in order of removed, added, updated.
    struct TreeControllerEvent {
        var removed: [IndexPath]
        var added: [IndexPath]
        var updated: [IndexPath]
        var moved: [MovedModel]
    }
    
    public final var proxiedObservable: Observable<TreeControllerEvent> { return observers }
    private final let observers: ObserverList<TreeControllerEvent>

    // MARK: Private

    private weak var parent: NestedModelCollectionTreeController? = nil
    private let modelId: ModelId?
    private var childrenCache = [ModelId: NestedModelCollectionTreeController]()
    private var modelCollectionCache = [ModelId: (Int, Model)]()
    private let modelCollection: NestedModelCollection
    private var modelCollectionObserver: Subscription?
    private var diffEngine = DiffEngine()

    private var indexPath: IndexPath {
        guard let parent = parent, let modelId = modelId else { return IndexPath() }
        guard let index = parent.modelCollectionCache[modelId]?.0 else {
            Log.fatal(message: "Parent of model collection no longer knows about child")
        }
        return parent.indexPath.appending(index)
    }

    private func handleCollectionEvent(_ event: CollectionEvent) {
        guard case .didChangeState(let state) = event else { return }

        recreateModelCollectionCache()

        let indexPath = self.indexPath
        let changes = diffEngine.update([state.models])
        guard changes.hasUpdates else { return }
        let updatedIndexPaths = changes.updatedModelPaths.map {
            indexPath.appending($0.itemIndex)
        }
        let addedIndexPaths = changes.addedModelPaths.map {
            indexPath.appending($0.itemIndex)
        }
        let removedIndexPaths = changes.removedModelPaths.map {
            indexPath.appending($0.itemIndex)
        }
        let movedPaths = changes.movedModelPaths

        let modelIds = Set(modelCollection.models.map({ $0.modelId }))
        childrenCache = childrenCache.filter {
            modelIds.contains($0.key)
        }
        let event = TreeControllerEvent(
            removed: removedIndexPaths,
            added: addedIndexPaths,
            updated: updatedIndexPaths,
            moved: movedPaths)
        observers.notify(event)
    }

    private func findOrCreateNode(_ path: TreePath) -> NestedModelCollectionTreeController {
        guard !path.components.isEmpty else { return self }
        let modelId = path.components[0]
        if let cached = childrenCache[modelId] {
            return cached.findOrCreateNode(path.dropFirst())
        } else {
            guard let model = modelCollectionCache[modelId]?.1 else {
                Log.fatal(message: "Attempted to fetch node for missing leaf")
            }
            let childModelCollection = modelCollection.childModelCollection(for: model)
            let node = NestedModelCollectionTreeController(
                modelCollection: childModelCollection,
                modelId: modelId,
                parent: self)
            childrenCache[modelId] = node
            return node.findOrCreateNode(path.dropFirst())
        }
    }

    private func recreateModelCollectionCache() {
        var modelCache = [ModelId: (Int, Model)]()
        for (index, model) in modelCollection.models.enumerated() {
            modelCache[model.modelId] = (index, model)
        }
        self.modelCollectionCache = modelCache
    }
}

extension NestedModelCollectionTreeController: Equatable {}
