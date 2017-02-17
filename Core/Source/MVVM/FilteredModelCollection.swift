import Foundation

/// Filter closure - returns `true` to include the element, and `false` to exclude (same as `Array.filter`).
public typealias ModelFilter = (Model) -> Bool

/// `ModelCollectionType` which provides basic filter support on top of an existing source `ModelCollectionType`.
public final class FilteredModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public init(
        sourceCollection: ModelCollection,
        kind: FilterKind = .sync,
        filter: ModelFilter? = nil
    ) {
        self.sourceCollection = sourceCollection
        self.kind = kind

        sourceObserver = self.sourceCollection.observe { [weak self] event in
            self?.handleSourceEvent(event)
        }

        sections = self.sourceCollection.sections
        state = self.sourceCollection.state

        if let filter = filter {
            self.filter = filter
            runFilter()
        }
    }

    // MARK: Public

    public var limit: Int? = nil {
        willSet {
            discardPendingFilterWork()
        }
        didSet {
            // Don't need to run the filter yet if still loading (otherwise observers will think this has loaded when
            // the spinner completes). It will get run when data comes in.
            guard !state.isLoading else { return }
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
            // Don't need to run the filter yet if still loading (otherwise observers will think this has loaded when
            // the spinner completes). It will get run when data comes in.
            guard !state.isLoading else { return }
            runFilter()
        }
    }

    // MARK: ModelCollection

    /// Designates how the filter runs, either `.sync` or `.async`. If async a queue should be specified on which
    /// to run the filter e.g. `Queue.userInitiated`. This should only be used if experiencing noticable performace
    /// issues when running complex filtering or using very large datasets. Note that when using `.async` the filter
    /// closure should capture everything it needs to perform the query and be careful not to reference objects
    /// across threads.
    public enum FilterKind {
        case sync
        case async(queue: Queue)

        func run(_ filter: @escaping () -> Void, then postFilter: @escaping () -> Void) {
            switch self {
            case .sync:
                filter()
                postFilter()
            case .async(let queue):
                Async.on(queue, block: filter).onMain(postFilter)
            }
        }
    }

    public var collectionId: ModelId {
        return "filtered-\(sourceCollection.collectionId)"
    }

    public private(set) var sections: [[Model]] = [[]]

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

    public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    private let kind: FilterKind
    private let sourceCollection: ModelCollection
    private var sourceObserver: Observer?

    private func handleSourceEvent(_ event: CollectionEvent) {
        filterResults = nil
        discardPendingFilterWork()
        if case .didChangeState(let state) = event, case .loaded = state {
            runFilter()
        }
    }

    private var filterCookie = 0

    private func discardPendingFilterWork() {
        assert(Thread.isMainThread)
        filterCookie += 1
    }

    /// Cache of the results of the last filter pass for each item
    private var filterResults: [[Bool]]?

    private func runFilter() {
        assert(Thread.isMainThread)

        let originalSections = sourceCollection.sections
        let originalFilter = filter
        let originalCookie = filterCookie
        let originalIncluded = filterResults
        let originalLimit = limit

        state = .loading(state.sections)

        var newFilterResults: [[Bool]] = []
        var newFilteredSections: [[Model]] = []
        var insertedIndexPaths: [ModelPath] = []
        var removedIndexPaths: [ModelPath] = []

        let filterCollection = {
            var itemCount = 0
            // Core filtering work.
            for (sectionIndex, sectionModels) in originalSections.enumerated() {
                // To avoid making multiple passes through the collection, we compare filter results to a saved copy of
                // the results from the previous filter (when that exists). As we increment through the models we keep a
                // pointer to the current index to insert the next row if its included in the new filter, and not the
                // old one. As well as a pointer that increments for every row included previously so that we can delete
                // the row for the current item if its not included by the new filter but was by the old one.
                var insertionIndex = 0
                var deletionIndex = 0
                let previousResults = originalIncluded?[sectionIndex]
                var sectionFilterResults = [Bool]()
                var section = [Model]()
                for (itemIndex, model) in sectionModels.enumerated() {
                    var shouldInclude = originalFilter(model)
                    if let limit = originalLimit , itemCount >= limit {
                        shouldInclude = false
                    }
                    if shouldInclude {
                        itemCount += 1
                    }
                    sectionFilterResults.append(shouldInclude)
                    if shouldInclude {
                        section.append(model)
                        if previousResults?[itemIndex] == false {
                            insertedIndexPaths.append(ModelPath(
                                sectionIndex: sectionIndex,
                                itemIndex: insertionIndex))
                        }
                        insertionIndex += 1
                    } else {
                        if previousResults?[itemIndex] == true {
                            removedIndexPaths.append(ModelPath(
                                sectionIndex: sectionIndex,
                                itemIndex: deletionIndex))
                        }
                    }
                    if previousResults?[itemIndex] == true {
                        deletionIndex += 1
                    }
                }
                newFilterResults.append(sectionFilterResults)
                newFilteredSections.append(section)
            }
        }

        let updateCollection = { [weak self] in
            guard let strongSelf = self else { return }

            // Drop work if the cookie is outdated.
            guard originalCookie == strongSelf.filterCookie else {
                return
            }

            // Update state and notify observers.
            strongSelf.filterResults = newFilterResults
            strongSelf.state = .loaded(newFilteredSections)
        }

        kind.run(filterCollection, then: updateCollection)
    }
}
