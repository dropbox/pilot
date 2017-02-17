import Foundation

// MARK: `MultiplexModelCollection`

/// A type of `ModelCollection` which encapsulates an array of ModelCollections,
/// mapping each section of those ModelCollections to a section of the ModelCollection
/// it represents.
/// Example: if it represents three ModelCollections, each with a single section,
/// The resulting ModelCollection will have three sections, mapped like this:
///  Collection[0], section[0] -> section[0]
///  Collection[1], section[0] -> section[1]
///  Collection[2], section[0] -> section[2]
/// If the component ModelCollections have multiple sections, they should be slotted in in order.
/// Example, if one of the collections has 2 sections:
///  Collection[0], section[0] -> section[0]
///  Collection[1], section[0] -> section[1]
///  Collection[1], section[1] -> section[2]
///  Collection[2], section[0] -> section[3]
public final class MultiplexModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public required init(_ modelCollections: [ModelCollection]) {
        // Create a worker queue for processing/diffing incoming events.
        let queue = DispatchQueue(label: "com.dropbox.pilot.queue.store_model_collection", attributes: [])
        self.eventProcessingQueue = Queue.custom(queue)

        self.modelCollections = modelCollections

        // Update state to match the contained ModelCollections, since they may not start in the NotLoaded state.
        state = multiSectionCollectionStateFromSubcollectionStates(modelCollections.map({ $0.state }))

        beginObservingModelCollections()
    }

    // MARK: ModelCollectionObservable

    public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    /// Observe each of the contained ModelCollections, and handle the various ModelCollection events that they send.
    private func beginObservingModelCollections () {
        for collection in modelCollections {
            let observer = collection.observe { [weak self] collectionEvent in
                self?.handleCollectionEvent(collection, event: collectionEvent)
            }
            observationTokens.append(observer)
        }
    }

    /// Given a collection (should be one of our subcollections), return the section
    /// index of our ModelCollection corresponding to the zeroth section of the subcollection.
    /// If the input is our modelCollections[0], result should be zero
    /// If the input is our modelCollections[1], result should be  modelCollections[0].totalItemCount, etc.
    /// If the input is not one of the subcollections, result should be nil: this is why the return type is an optional
    private func sectionIndexFromSubcollection(_ collection: ModelCollection) -> Int? {
        var sectionIndex: Int = 0
        for subcollection in modelCollections {
           if subcollection.collectionId == collection.collectionId {
                return sectionIndex
            } else {
                if subcollection.sections.isEmpty {
                    // Account for the empty section added when subcollection is empty.
                    sectionIndex = sectionIndex + 1
                } else {
                    sectionIndex = sectionIndex + subcollection.sections.count
                }
            }
        }
        return nil
    }

    /// This ModelCollection's state derives from the states of all its subcollections.
    /// This function takes an array of CollectionStates and distills them into a single state
    /// Strategy :
    ///    if all substates are .NotLoaded, then result is .NotLoaded
    ///    else if all substates are .Loaded, then result is .Loaded
    ///    else if any of substates are .Error(x), then result is .Error(MultiplexedError(errors: [x]))
    ///    else if this instance has been previously loaded, then result is .loading(<combined sections>)
    ///    else result is .loading(nil)
    ///
    /// The most straightforward approach seems to be to reduce into a struct that maintains a count
    /// of all the different subcollection states, and then process the reduced result
    ///
    /// This seems like overkill for the likeliest scenario of two CollectionStates, but oh, well.
    private func multiSectionCollectionStateFromSubcollectionStates(
        _ substates: [ModelCollectionState]
    ) -> ModelCollectionState {

        var consolidatedSections: [[Model]] = []
        for substate in substates {
            // For model collections that are completely empty insert an empty section as a placeholder.
            if substate.sections.isEmpty {
                consolidatedSections.append([])
            } else {
                substate.sections.forEach {
                    consolidatedSections.append($0)
                }
            }
        }

        // swiftlint:disable nesting
        struct CollectionStateReduction {
            var notLoadedCount = 0
            var loadingCount = 0
            var loadedCount = 0
            var loadingMoreCount = 0
            var errorArray: [Error] = []
        }
        // swiftlint:enable nesting

        let initialReducedStates = CollectionStateReduction()
        let reducedStates = substates.reduce(initialReducedStates) { prevCollectionStateCounts, state in
            var newCollectionStateCounts = prevCollectionStateCounts
            switch state {
            case .notLoaded:
                newCollectionStateCounts.notLoadedCount += 1
            case .loaded:
                newCollectionStateCounts.loadedCount += 1
            case .error(let error):
                newCollectionStateCounts.errorArray.append(error)
            case .loading(let models):
                if models == nil {
                    newCollectionStateCounts.loadingCount += 1
                } else {
                    newCollectionStateCounts.loadingMoreCount += 1
                }
            }
            return newCollectionStateCounts
        }

        if !reducedStates.errorArray.isEmpty {
            let error = MultiplexedError(errors: reducedStates.errorArray)
            return .error(error)
        } else if reducedStates.notLoadedCount == substates.count {
            return .notLoaded
        } else if reducedStates.loadedCount == substates.count {
            return .loaded(consolidatedSections)
        } else if hasEverBeenInLoadedState {
            return .loading(consolidatedSections)
        } else {
            return .loading(nil)
        }
    }

    private func subcollectionStatesDictionary() -> [ModelId : ModelCollectionState] {
        var dict = [ModelId : ModelCollectionState]()
        for collection in modelCollections {
            dict[collection.collectionId] = collection.state
        }
        return dict
    }

    /// Listens for events from each of the subcollections and pass these events on to observers.
    /// Maps the affected subcollection, section and item index into the correct section and item
    /// index so that observers know what changes have happened.
    private func handleCollectionEvent(_ collection: ModelCollection, event: CollectionEvent) {
        state = multiSectionCollectionStateFromSubcollectionStates(modelCollections.map({ $0.state }))
    }

    //  MARK: ModelCollection

    public let collectionId: ModelCollectionId = { return "concat-\(UUID().uuidString)" }()

    public struct MultiplexedError: Error {
        public var errors: [Error]
    }

    public private(set) var state = ModelCollectionState.notLoaded {
        didSet {
            observers.notify(.didChangeState(state))
            if case .loaded = state {
                hasEverBeenInLoadedState = true
            }
        }
    }

    // In order to distinguish between .loading(nil) and .loading([...]),
    // remember if this instance has ever gotten to the .Loaded state
    private var hasEverBeenInLoadedState: Bool = false

    // modelCollections -- this is the array of collections this object is 'multiplexing'
    private let modelCollections: [ModelCollection]

    // set of observer tokens for each of the subcollections
    private var observationTokens: [Observer] = []

    // maintain queue to ensure that events are processed serially
    private let eventProcessingQueue: Queue

}
