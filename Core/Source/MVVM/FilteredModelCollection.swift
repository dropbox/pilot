import Foundation

/// Filter closure - returns `true` to include the element, and `false` to exclude (same as `Array.filter`).
public typealias ModelFilter = (Model) -> Bool

/// `ModelCollectionType` which provides basic filter support on top of an existing source `ModelCollectionType`.
public final class FilteredModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    /// Designates how the filter runs, either `.sync` or `.async`. If async a queue should be specified on which
    /// to run the filter e.g. `Queue.userInitiated`. This should only be used if experiencing noticable performace
    /// issues when running complex filtering or using very large datasets. Note that when using `.async` the filter
    /// closure should capture everything it needs to perform the query and be careful not to reference objects
    /// across threads.
    public enum FilterKind {
        case sync
        case async(queue: Queue)

        fileprivate func run(_ filter: @escaping () -> Void, then postFilter: @escaping () -> Void) {
            switch self {
            case .sync:
                filter()
                postFilter()
            case .async(let queue):
                Async.on(queue, block: filter).onMain(postFilter)
            }
        }
    }

    // MARK: Init

    public init(
        sourceCollection: ModelCollection,
        kind: FilterKind = .sync,
        filter: ModelFilter? = nil
    ) {
        self.sourceCollection = sourceCollection
        self.kind = kind

        sourceObserver = self.sourceCollection.observeValues { [weak self] event in
            self?.handleSourceEvent(event)
        }

        if let filter = filter {
            self.filter = filter
        }
        runFilter()
    }

    // MARK: Public

    /// Limit the number of items to include in the filtered collection (applied after filter).
    public var limit: Int? = nil {
        willSet {
            discardPendingFilterWork()
        }
        didSet {
            runFilter()
        }
    }

    /// Closure expression that takes a `Model` and should return `true` if the model should remain in the collection.
    /// Assigning this property run the filter immediately on the collection.
    /// NOTE: If using the `async` option beware your closure expression referencing objects across threads.
    public var filter: ModelFilter = { model in return true } {
        willSet {
            discardPendingFilterWork()
        }
        didSet {
            runFilter()
        }
    }

    // MARK: ModelCollection

    public var collectionId: ModelId {
        return "filtered-\(sourceCollection.collectionId)"
    }

    public internal(set) var state = ModelCollectionState.notLoaded {
        didSet {
            observers.notify(.didChangeState(state))
        }
    }

    /// Re-runs the current `filter` on the underlying collection.
    public func rerunFilter() {
        discardPendingFilterWork()
        runFilter()
    }

    // MARK: CollectionEventObservable

    public var proxiedObservable: Observable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    private let kind: FilterKind
    private let sourceCollection: ModelCollection
    private var sourceObserver: Subscription?

    private func handleSourceEvent(_ event: CollectionEvent) {
        discardPendingFilterWork()
        runFilter()
    }

    private var filterCookie = 0

    private func discardPendingFilterWork() {
        assert(Thread.isMainThread)
        filterCookie += 1
    }

    private func runFilter() {
        assert(Thread.isMainThread)

        let originalSections = sourceCollection.models
        let originalFilter = filter
        let originalCookie = filterCookie
        let originalLimit = limit

        state = .loading(state.models)

        var newFilteredSections: [Model] = []

        let filterCollection = {
            var itemCount = 0
            // TODO:(danielh) evaluate checking cancelled check to this loop
            for model in originalSections {
                if originalFilter(model) {
                    newFilteredSections.append(model)
                    itemCount += 1
                    if let limit = originalLimit, itemCount >= limit {
                        break
                    }
                }
            }
        }

        let updateCollection = { [weak self] in
            assert(Thread.isMainThread)
            guard let strongSelf = self else { return }

            // Drop work if the cookie is outdated.
            guard originalCookie == strongSelf.filterCookie else {
                return
            }

            if strongSelf.sourceCollection.state.isLoading {
                strongSelf.state = .loading(newFilteredSections)
            } else {
                strongSelf.state = .loaded(newFilteredSections)
            }
        }

        kind.run(filterCollection, then: updateCollection)
    }
}
