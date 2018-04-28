import Foundation
import Pilot

/// Responsible for managing a lazily evaluated tree of nested model collections.
///
/// Intended to provide a wrapper around nested model collections for the OutlineTableViewModelDataSource and interface
/// is heavily optimized for that usecase (ie isExpandable and countOfChildNodes) as opposed to a general tree interface
/// and is designd to be addressed by IndexPaths that can be used as pointers back into specific models.
///
/// NOTE: NestedModelCollectionTreeController is considered == whenever the indexPath and ModelCollection ids are ==
internal final class NestedModelCollectionTreeController: ProxyingObservable {

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
            self.observers = ObserverList<Event>()
        }
        // Update diff engine state up to current state of ModelCollection so future calls to .update get correct diffs.
        _ = diffEngine.update([modelCollection.models])
        self.modelCollectionObserver = modelCollection.observe { [weak self] (event) in
            self?.handleCollectionEvent(event)
        }
    }

    internal func isExpandable(_ path: IndexPath) -> Bool {
        let model = modelAtIndexPath(path)
        let containingNode = findOrCreateNode(path.dropLast())
        return containingNode.modelCollection.canExpand(model)
    }

    internal func countOfChildNodes(_ path: IndexPath) -> Int {
        return findOrCreateNode(path).modelCollection.models.count
    }

    internal func modelAtIndexPath(_ path: IndexPath) -> Model {
        guard !path.isEmpty else { Log.fatal(message: "Empty path passed to modelAtIndexPath()") }
        let containingNode = findOrCreateNode(path.dropLast())
        return containingNode.modelCollection.models[path.last!]
    }

    internal var indexPath: IndexPath {
        // TODO:(danielh) This is very inefficient, though thankfully isn't called super often, optimize once there's
        // enough test coverage to ensure correctness.
        guard let parent = parent, let modelId = modelId else { return IndexPath() }
        guard let index = parent.modelCollection.models.index(where: { $0.modelId == modelId }) else {
            Log.fatal(message: "Parent of model collection no longer knows about child")
        }
        return parent.indexPath.appending(index)
    }

    internal weak var parent: NestedModelCollectionTreeController? = nil

    // MARK: Observable

    /// Description of mutations to model collection tree.
    ///
    /// IndexPaths are consistent when interpreted in order of removed, added, updated.
    struct Event {
        var removed: [IndexPath]
        var added: [IndexPath]
        var updated: [IndexPath]
    }

    public final var proxiedObservable: GenericObservable<Event> { return observers }
    private final let observers: ObserverList<Event>

    // MARK: Private

    private let modelId: ModelId?
    private var childrenCache = [ModelId: NestedModelCollectionTreeController]()
    private let modelCollection: NestedModelCollection
    private var modelCollectionObserver: Observer?
    private var diffEngine = DiffEngine()

    private func handleCollectionEvent(_ event: CollectionEvent) {
        guard case .didChangeState(let state) = event else { return }
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
        let modelIds = Set(modelCollection.models.map({ $0.modelId }))
        childrenCache = childrenCache.filter {
            modelIds.contains($0.key)
        }
        let event = Event(removed: removedIndexPaths, added: addedIndexPaths, updated: updatedIndexPaths)
        observers.notify(event)
    }

    private func findOrCreateNode(_ path: IndexPath) -> NestedModelCollectionTreeController {
        guard !path.isEmpty else { return self }
        let model = modelCollection.models[path[0]]
        if let cached = childrenCache[model.modelId] {
            return cached.findOrCreateNode(path.dropFirst())
        } else {
            let childModelCollection = modelCollection.childModelCollection(for: model)
            let node = NestedModelCollectionTreeController(
                modelCollection: childModelCollection,
                modelId: model.modelId,
                parent: self)
            childrenCache[model.modelId] = node
            return node.findOrCreateNode(path.dropFirst())
        }
    }
}

extension NestedModelCollectionTreeController: Equatable {
    static func ==(lhs: NestedModelCollectionTreeController, rhs: NestedModelCollectionTreeController) -> Bool {
        return lhs.indexPath == rhs.indexPath && lhs.modelCollection.collectionId == rhs.modelCollection.collectionId
    }
}
