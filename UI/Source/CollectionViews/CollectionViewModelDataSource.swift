import Pilot
import QuartzCore
#if canImport(RxSwift)
import RxSwift
#endif

/// Can be used to provide reuse ids for collection view cells.
public protocol CollectionViewCellReuseIdProvider {
    func reuseIdForViewModel(_ viewModel: ViewModel, viewType: View.Type) -> String
}

open class DefaultCollectionViewCellReuseIdProvider: CollectionViewCellReuseIdProvider {
    public init() {
    }

    // MARK: CollectionViewCellReuseIdProvider

    /// The default implementation, if a provider isn't specified in the initializer.
    open func reuseIdForViewModel(_ viewModel: ViewModel, viewType: View.Type) -> String {
        return "\(NSStringFromClass(viewType))-\(type(of: viewModel))"
    }
}

private enum CollectionViewState {
    /// Don't know exactly what the CollectionView thinks the world looks like until it asks for the section count.
    case loading

    /// Told CollectionView to performBatchUpdates but it hasn't completed yet.
    case animating

    /// If the underlying ModelCollection has changed while animating, it must be updated again when the animation
    /// completes.
    case animatingWithPendingChanges

    /// The CollectionView and ModelCollection are in sync with each other.
    case synced
}

public final class CurrentCollection: SectionedModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public init(_ collectionId: ModelCollectionId) {
        self.collectionId = collectionId
    }

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId

    public var state: ModelCollectionState {
        // Dynamic getter because `sectionedState` is the source-of-truth for this class.
        return sectionedState.flattenedState()
    }

    public var proxiedObservable: Observable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: SectionedModelCollection

    public private(set) var sectionedState: [ModelCollectionState] = []  {
        didSet {
            observers.notify(.didChangeState(state))
        }
    }

    // MARK: Private

    fileprivate func beginUpdate(_ collection: ModelCollection) -> (CollectionEventUpdates, () -> Void){
        // If the collection is already sectioned, this will honor those sections. Otherwise, it will
        // provide a single section wrapping the original collection.
        let sectionedCollection = collection.asSectioned()
        let updates = diffEngine.update(sectionedCollection.sections, debug: false)
        let commitSectionedState = sectionedCollection.sectionedState
        return (updates, {
            self.sectionedState = commitSectionedState
        })
    }

    fileprivate func update(_ collection: ModelCollection) {
        let (_, commitCollectionChanges) = beginUpdate(collection)
        commitCollectionChanges()
    }

    private var diffEngine = DiffEngine()
}

/// Data source for collection views which handles all the necessary binding between models -> view models, and view
/// models -> view types. It handles observing the underlying model and handling all required updates to the collection
/// view.
public class CollectionViewModelDataSource: NSObject, ProxyingObservable {

    // MARK: Init

    public init(
        model: ModelCollection,
        modelBinder: ViewModelBindingProvider,
        viewBinder: ViewBindingProvider,
        context: Context,
        reuseIdProvider: CollectionViewCellReuseIdProvider
    ) {
        self.underlyingCollection = model
        self.currentCollection = CurrentCollection("CVMDS-Current")
        self.modelBinder = modelBinder
        self.viewBinder = viewBinder
        self.context = context
        self.reuseIdProvider = reuseIdProvider

        self.collectionViewState = .loading

        super.init()

        self.collectionObserver = self.underlyingCollection.observeValues { [weak self] event in
            self?.handleCollectionEvent(event)
        }

        registerForNotifications()
    }

    deinit {
        unregisterForNotifications()
    }

    // MARK: Public

    public enum Event {
        /// `willUpdateItems` is triggered when the underlying ModelCollection has changed its data, but the
        /// updates have not been applied to either the CollectionView or `currentCollection`.
        /// While handling this event, `currentCollection` contains the collection's contents before the change.
        case willUpdateItems(CollectionEventUpdates)

        /// `didUpdateItems` is triggered after the ModelCollection has changed and the CollectionView has
        /// finished animating to the new state.
        /// Implementation note: In the case of a reload, this event can fire before the CollectionView has updated
        /// with the new contents.
        case didUpdateItems(CollectionEventUpdates)
    }

    /// A ModelCollection that provides access to the data as far as the CollectionView knows.  If the CollectionView
    /// is in the process of being updated, this data might be slightly behind the ModelCollection passed as the constructor.
    /// The data in `currentCollection` is updated between the `willUpdateItems` and `didUpdateItems` events.
    public let currentCollection: CurrentCollection

    /// Underlying model context.
    public private(set) var context: Context

    /// Associated collection view for this data source. The owner of the `CollectionViewModelDataSource` should set
    /// this property after initialization.
    public weak var collectionView: PlatformCollectionView? {
        willSet {
            precondition(newValue != nil)

            // TODO(wkiefer) T126138: NestedModelCollectionView binds and unbinds to a data source. We'll have to make
            // this class support attach/detatch from a collection view properly.
            // precondition(collectionView == nil)
        }
    }

    /// Adds a `ViewModelBindingProvider` for any supplementary views of `kind`. If not set the
    /// `DefaultViewModelBindingProvider` is used.
    open func setViewModelBinder(_ binder: ViewModelBindingProvider, forSupplementaryElementOfKind kind: String) {
        supplementaryViewModelBinderMap[kind] = binder
    }

    /// Removes any `ViewModelBindingProvider` for supplementary views of `kind`. Once cleared the
    /// `DefaultViewModelBindingProvider` will be used.
    open func clearViewModelBinder(forSupplementaryElementOfKind kind: String) {
        supplementaryViewModelBinderMap[kind] = nil
    }

    /// Adds a `ViewBindingProvider` to provide views for any supplementary views of the given `kind`.
    open func setViewBinder(_ viewBinder: ViewBindingProvider, forSupplementaryElementOfKind kind: String) {
        supplementaryViewBinderMap[kind] = viewBinder
    }

    /// Removes a previously-added `ViewBindingProvider` for supplementary views.
    open func clearViewBinderForSupplementaryElementOfKind(_ kind: String) {
        supplementaryViewBinderMap[kind] = nil
    }

    /// Adds an `IndexedModelProvider` for any supplementary views of `kind`. If not set,
    /// supplementary views default to the ModelType provided by the ModelCollection for the given
    /// index path, or a CollectionZeroItemModel otherwise.
    public func setModelProvider(provider: IndexedModelProvider, forSupplementaryElementOfKind kind: String) {
        supplementaryModelProviderMap[kind] = provider
    }

    /// Removes a previously-added `IndexedModelProvider` for supplementary views.
    public func clearModelProviderForSupplementaryElementOfKind(kind: String) {
        supplementaryModelProviderMap[kind] = nil
    }

#if os(iOS)
    /// Configures the default background color for all host cells.
    open var collectionViewBackgroundColor = UIColor.white
#endif

    /// Method to return the preferred layout for a given item. Typically collection view controllers would implement
    /// any layout delegate methods that need a size, and call into this to fetch the desired size for an item.
    /// TODO(ca): change this to take a ModelPath instead of the heavier IndexPath
    open func preferredLayoutForItemAtIndexPath(
        _ indexPath: IndexPath,
        availableSize: AvailableSize) -> PreferredLayout {
        guard let modelItem: Model = currentCollection.atIndexPath(indexPath) else { return .none }
        var cachedViewModel = self.cachedViewModel(for: modelItem)
        if let layout = cachedViewModel.preferredLayout.layout {
            if layout.validCache(forViewModel: cachedViewModel.viewModel) {
                return cachedViewModel.preferredLayout
            }
        }
        cachedViewModel.preferredLayout = viewBinder.preferredLayout(
            fitting: availableSize,
            for: cachedViewModel.viewModel,
            context: context)
        viewModelCache[modelItem.modelId] = cachedViewModel
        return cachedViewModel.preferredLayout
    }

    /// Same as `preferredLayoutForItemAtIndexPath:availableSize:` but for supplementary view size estimation.
    open func preferredLayoutForSupplementaryElementAtIndexPath(
        _ indexPath: IndexPath,
        kind: String,
        availableSize: AvailableSize
    ) -> PreferredLayout {
        guard let supplementaryViewBinder = supplementaryViewBinderMap[kind] else {
            Log.fatal(message: "Request for supplementary kind (\(kind)) that has no registered view binder.")
        }
        let viewModel = viewModelForSupplementaryElementAtIndexPath(kind, indexPath: indexPath)

        // TODO:(wkiefer) Cache supplementary sizes too.
        return supplementaryViewBinder.preferredLayout(
            fitting: availableSize,
            for: viewModel,
            context: context)
    }

#if os(iOS)
    /// Attempts to reload a supplementary element at index path by re-binding the hosted view to the view model
    /// Note: This function makes no attempt to determine whether layout needs to be invalidated, so if you're making an
    /// update that should trigger the collection view layout being invalidated make sure to do that separately.
    open func reloadSupplementaryElementAtIndexPath(_ indexPath: IndexPath, kind: String) {
        guard let cv = collectionView else { return }
        let supplementaryView = cv.supplementaryView(forElementKind: kind, at: indexPath)
        guard let hostView = supplementaryView as? CollectionViewHostReusableView else { return }
        guard let hostedView = hostView.hostedView else { return }
        let viewModel = viewModelForSupplementaryElementAtIndexPath(kind, indexPath: indexPath)
        hostedView.bindToViewModel(viewModel)
        hostView.hostedView = hostedView
    }
#elseif os(OSX)
    /// Attempts to reload a supplementary element at index path by re-binding the hosted view to the view model
    /// Note: This function makes no attempt to determine whether layout needs to be invalidated, so if you're making an
    /// update that should trigger the collection view layout being invalidated make sure to do that separately.
    public func reloadSupplementaryElementAtIndexPath(indexPath: IndexPath, kind: String) {
        guard let cv = collectionView else { return }
        guard let supplementaryViewBinder = supplementaryViewBinderMap[kind] else { return }

        let supplementaryView = cv.supplementaryView(forElementKind: NSCollectionView.SupplementaryElementKind(rawValue: kind), at: indexPath)
        guard let hostView = supplementaryView as? CollectionViewHostReusableView else { return }
        guard var hostedView = hostView.hostedView else { return }

        let viewModel = viewModelForSupplementaryElementAtIndexPath(kind, indexPath: indexPath)
        hostedView = supplementaryViewBinder.view(for: viewModel, context: context, reusing: hostedView, layout: nil)

        hostView.hostedView = hostedView
        hostedView.bindToViewModel(viewModel)
    }
#endif

    /// Returns a bound `ViewModel` for the given `indexPath` or nil if the index path is not valid.
    open func viewModelAtIndexPath(_ indexPath: IndexPath) -> ViewModel? {
        guard let modelItem: Model = currentCollection.atIndexPath(indexPath as IndexPath) else { return nil }
        return cachedViewModel(for: modelItem).viewModel
    }

    /// Block which is invoked anytime a view model will be rebound to a view (typically during updates that don't
    /// require a reload of the cell).
    open var willRebindViewModel: (ViewModel) -> Void = { _ in }

    /// Clears any internally-cached preferred item size calculations. Should typically be called when the size of the
    /// collection view will change.
    open func clearCachedItemSizes() {
        var mutatedViewModelCache: [ModelId: CachedViewModel] = [:]

        for (key, cachedViewModel) in viewModelCache {
            var updatedCachedViewModel = cachedViewModel
            updatedCachedViewModel.preferredLayout = .none
            mutatedViewModelCache[key] = updatedCachedViewModel
        }
        viewModelCache = mutatedViewModelCache
    }

    /// Possible styles for any model update animations.
    public enum UpdateAnimationStyle {
        /// All model update changes are animated.
        case always
        /// The given update is animated depending on the result of the associated closure.
        case conditional((CollectionEventUpdates) -> Bool)
        /// No updates are animated, but updates are incremental.
        case none
        /// No updates are animated, and all updates reload all data.
        case noneReloadOnly
    }

    /// Current update animation style. For details see `UpdateAnimationStyle`.
    open var updateAnimationStyle = UpdateAnimationStyle.always

    /// Returns whether the given `CollectionEventUpdates` should animate depending on the current value of
    /// `updateAnimationStyle` and the contents of the updates.
    open func shouldAnimateUpdates(_ updates: CollectionEventUpdates) -> Bool {
        switch updateAnimationStyle {
        case .always:
            return true
        case .none, .noneReloadOnly:
            return false
        case .conditional(let shouldAnimate):
            return shouldAnimate(updates)
        }
    }

    /// Provider for collection reuse ids. This is set with a default based on the names of the
    /// ViewModel and View, but can be overridden to optimize reuse ids for a collection.
    public let reuseIdProvider: CollectionViewCellReuseIdProvider

    // MARK: ObservableType

    public var proxiedObservable: Observable<Event> { return observers }
    private let observers = ObserverList<Event>()

    // MARK: Private

    private let modelBinder: ViewModelBindingProvider
    private let viewBinder: ViewBindingProvider

    /// The collection whose contents are synchronized to this CollectionView.
    /// The underlyingCollection's data may be newer than the CollectionView's understanding of the world.
    private let underlyingCollection: ModelCollection
    private var collectionViewState: CollectionViewState

    private var collectionObserver: Subscription?

    /// Cache of view models and sizing information.
    private var viewModelCache: [ModelId: CachedViewModel] = [:]

    /// Map from supplementary element kind (as `String`) to binding providers for supplementary views.
    private var supplementaryViewBinderMap: [String: ViewBindingProvider] = [:]

    /// Map from supplementary element kind (as `String`) to binding providers for supplementary view models.
    private var supplementaryViewModelBinderMap: [String: ViewModelBindingProvider] = [:]

    /// Map from supplementary element kind (as `String`) to model provider for supplementary elements.
    private var supplementaryModelProviderMap: [String: IndexedModelProvider] = [:]

    private var notificationTokens: [NSObjectProtocol] = []
    private var inBackground = false

    private func registerForNotifications() {
#if os(iOS)
        let nc = NotificationCenter.default

        // Note: Rather than observer `UIApplicationWillEnterForegroundNotification`, didBecomeActive is watched instead
        // because typically it's better for collection view updates to batch until actually active (instead of multiple
        // animations as the application is transitioning).
        notificationTokens.append(nc.addObserver(
            forName: NSNotification.Name.UIApplicationDidBecomeActive,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                self?.inBackground = false
            })
        notificationTokens.append(nc.addObserver(
            forName: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                self?.inBackground = true
        })
#endif // os(iOS)
    }

    private func unregisterForNotifications() {
        let nc = NotificationCenter.default
        notificationTokens.forEach { nc.removeObserver($0) }
        notificationTokens.removeAll()
    }

    private func modelForSupplementaryIndexPath(_ indexPath: IndexPath, ofKind kind: String) -> Model {
        if let provider = supplementaryModelProviderMap[kind] {
            // If a provider was set, and that provider provides a model, use it.
            if let model = provider.model(for: indexPath, context: context) {
                return model
            }
        } else if let modelItem: Model = currentCollection.atIndexPath(indexPath) {
            // If no provider is set but the collection model provides an item at this index path,
            // use that one.
            return modelItem
        }

        // If either a provider is set but provides no item, or there is no provider set and the
        // collection model does provides no item (such as when a section is empty),
        // return a "zero" item.
        return CollectionZeroItemModel(indexPath: indexPath)
    }

    private func viewModelForSupplementaryElementAtIndexPath(_ kind: String, indexPath: IndexPath) -> ViewModel {
        let model = modelForSupplementaryIndexPath(indexPath, ofKind: kind)
        if let bindingProvider = supplementaryViewModelBinderMap[kind] {
            // Supplementary items don't necessarily have an item associated with them (think section headers for empty
            // sections) - so handle the "zero" case here.
            if let zeroModel = model as? CollectionZeroItemModel {
                return CachedViewModel(
                    viewModel: CollectionZeroItemViewModel(indexPath: zeroModel.indexPath),
                    preferredLayout: .none).viewModel
            }

            return bindingProvider.viewModel(for: model, context: context)
        } else {
            return cachedViewModel(for: model).viewModel
        }
    }

    private func cachedViewModel(for model: Model) -> CachedViewModel {
        // Supplementary items don't necessarily have an item associated with them (think section headers for empty
        // sections) - so handle the "zero" case here.
        if let zeroModel = model as? CollectionZeroItemModel {
            return CachedViewModel(
                viewModel: CollectionZeroItemViewModel(indexPath: zeroModel.indexPath),
                preferredLayout: .none)
        }

        // Return cached view model if there is one.
        if let viewModel = viewModelCache[model.modelId] {
            return viewModel
        }

        // Do binding.
        let viewModel = modelBinder.viewModel(for: model, context: context)
        let cachedViewModel = CachedViewModel(viewModel: viewModel, preferredLayout: .none)
        viewModelCache[model.modelId] = cachedViewModel

        return cachedViewModel
    }

    private func handleCollectionEvent(_ event: CollectionEvent) {
        switch collectionViewState {
        case .loading:
            // The collection changed, but the CollectionView hasn't asked for any information yet, so there's nothing to do.
            break
        case .animating:
            // CollectionView is currently animating, so indicate further updates are required when it's done.
            collectionViewState = .animatingWithPendingChanges
        case .animatingWithPendingChanges:
            // More changes? No problem.
            break
        case .synced:
            // Everyone is idle so kick off an update.
            applyCurrentDataToCollectionView()
        }
    }

    private func applyCurrentDataToCollectionView() {
        precondition(collectionViewState == .synced)

        let (updates, commitCollectionChanges) = currentCollection.beginUpdate(underlyingCollection)
        guard updates.hasUpdates else {
            // Still synced - no need to fire a collection view update pass.
            // However, if there are no updates, the underlying case of any section may still change
            // (e.g. .loading(_) -> .error(_)), so a commit is still needed.
            for (underlying, current) in Swift.zip(
                underlyingCollection.asSectioned().sectionedState,
                currentCollection.sectionedState
            ) {
                if underlying.isDifferentCase(than: current) {
                    commitCollectionChanges()
                    break
                }
            }
            return
        }

        observers.notify(.willUpdateItems(updates))
        commitCollectionChanges()

        handleUpdateItems(updates) { [weak self] in
            self?.observers.notify(.didUpdateItems(updates))
        }
    }


    private var collectionViewSectionCount: Int {
        return collectionView?.numberOfSections ?? 0
    }

    /// Clears any applicable cached view models (in `viewModelCache`) based on a set of `CollectionEventUpdates`.
    /// This method should only be called once the `CollectionEventUpdates` have been committed to `currentCollection`,
    /// typically in `handleUpdateItems(...)` as it assumes the updates are already reflected in the current collection.
    /// Returns the invalidated view models.
    private func invalidateViewModelCache(for updates: CollectionEventUpdates) -> [ModelId: CachedViewModel] {
        // Removals.
        for invalidatedModelId in updates.removedModelIds {
            viewModelCache[invalidatedModelId] = nil
        }

        var invalidatedViewModelCache: [ModelId: CachedViewModel] = [:]

        // At this point, `currentCollection` has been updated, and update/move.to index paths are based on post-removal
        // indices. So can clear based on state of current collection.
        for updatedPath in updates.updatedModelPaths {
            if let model: Model = currentCollection.atModelPath(updatedPath) {
                if let invalidViewModel = viewModelCache.removeValue(forKey: model.modelId) {
                    invalidatedViewModelCache[model.modelId] = invalidViewModel
                }
            }
        }

        for move in updates.movedModelPaths {
            if let model: Model = currentCollection.atModelPath(move.to) {
                if let invalidViewModel = viewModelCache.removeValue(forKey: model.modelId) {
                    invalidatedViewModelCache[model.modelId] = invalidViewModel
                }
            }
        }
        return invalidatedViewModelCache
    }
}

#if os(iOS)

// MARK: - iOS Data and Batch Updates

extension CollectionViewModelDataSource: UICollectionViewDataSource {

    // MARK: Private

    private func updatesShouldFallbackOnFullReload(_ updates: CollectionEventUpdates) -> Bool {
        // If `NoneReloadOnly` is specified, always reload.
        if case .noneReloadOnly = updateAnimationStyle {
            return true
        }

        // There is a long-standing `UICollectionView` bug where adding the first item or removing the last item within
        // a section can cause an internal exception. This method detects those cases and returns `true` if the update
        // should use a full data reload.
        return updates.containsFirstAddInSection || updates.containsLastRemoveInSection
    }

    public func handleUpdateItems(_ updates: CollectionEventUpdates, completion: @escaping () -> Void) {
        // preconditions
        precondition(collectionViewState == .synced) // but not for long!
        precondition(updates.hasUpdates)
        guard let collectionView = collectionView else {
            Log.fatal(message: "handleUpdateItems should never be called without a collectionView")
        }

        let invalidatedViewModelCache = invalidateViewModelCache(for: updates)


        // Workaround classic collection view bugs where some updates require using a full reload. This includes
        // reloading when the collection view is not part of the window hierarchy or the application is in the
        // background.
        let fullReloadFallback =
            updatesShouldFallbackOnFullReload(updates) || collectionView.window == nil || inBackground

        // Determine if this should be animated.
        let shouldAnimate = shouldAnimateUpdates(updates) && !fullReloadFallback

        // Set transaction start if animated.
        if !shouldAnimate {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }

        // Define the post-update completion block.
        let completionHandler = { [weak self] (finished: Bool) in
            if !shouldAnimate {
                CATransaction.commit()
            }

            if let strongSelf = self {
                switch strongSelf.collectionViewState {
                case .loading:
                    Log.fatal(message: "Precondition failure - state cannot transition from animating to loading")
                case .animating:
                    strongSelf.collectionViewState = .synced
                case .animatingWithPendingChanges:
                    strongSelf.collectionViewState = .synced // applyCurrentDataToCollectionView will update
                    strongSelf.applyCurrentDataToCollectionView()
                case .synced:
                    Log.fatal(message: "Precondition failure - state cannot transition from animating to synced")
                }
            }

            completion()
        }

        // If a full reload is needed, do so and exit early.
        guard !fullReloadFallback else {
            // On iOS `reloadData` doesn't always dequeue new cells, so remove and add all sections here.
            let oldSectionCount = collectionViewSectionCount
            let newSectionCount = currentCollection.sections.count

            collectionViewState = .animating
            collectionView.performBatchUpdates({
                collectionView.deleteSections(IndexSet(integersIn: 0..<oldSectionCount))
                collectionView.insertSections(IndexSet(integersIn: 0..<newSectionCount))
            }, completion: completionHandler)
            return
        }

        // Do actual batch updates.
        collectionViewState = .animating
        collectionView.performBatchUpdates({
            // Note: The ordering below is important and should not change. See note in
            // `CollectionEventUpdates`

            let removedSections = updates.removedSections
            if !removedSections.isEmpty {
                collectionView.deleteSections(IndexSet(removedSections))
            }
            let addedSections = updates.addedSections
            if !addedSections.isEmpty {
                collectionView.insertSections(IndexSet(addedSections))
            }

            let removed = updates.removedModelPaths
            if !removed.isEmpty {
                collectionView.deleteItems(at: removed.map { $0.indexPath })
            }
            let added = updates.addedModelPaths
            if !added.isEmpty {
                collectionView.insertItems(at: added.map { $0.indexPath })
            }
            for move in updates.movedModelPaths {
                collectionView.moveItem(at: move.from.indexPath, to: move.to.indexPath)
            }
        }, completion: completionHandler)

        // Note that reloads are done outside of the batch update call because they're basically unsupported
        // alongside other complicated batch updates. Because reload actually does a delete and insert under
        // the hood, the collectionview will throw an exception if that index path is touched in any other way.
        // Splitting the call out here ensures this is avoided.
        let updated = updates.updatedModelPaths
        if !updated.isEmpty {
            var indexPathsToReload: [IndexPath] = []
            let size = collectionView.bounds
            updated.forEach { indexPath in
                var oldCachedViewModel: CachedViewModel?
                var newCachedViewModel: CachedViewModel?

                // Create new view models from the updated models.
                if let model: Model = currentCollection.atModelPath(indexPath) {
                    oldCachedViewModel = invalidatedViewModelCache[model.modelId]

                    _ = cachedViewModel(for: model)

                    // Update the size.
                    // TODO:(wkiefer) Probably should cache last known available size - this makes some assumptions
                    // about available size.
                    let availableSize = AvailableSize(CGSize(width: size.width, height: CGSize.maxWindowSize.height))
                    _ = preferredLayoutForItemAtIndexPath(indexPath.indexPath, availableSize: availableSize)

                    newCachedViewModel = viewModelCache[model.modelId]
                }

                // If the size hasn't changed, simply rebind the view rather than perform a full cell reload.
                if
                    let old = oldCachedViewModel,
                    let new = newCachedViewModel,
                    type(of: old.viewModel) == type(of: new.viewModel) &&
                    old.preferredLayout == new.preferredLayout
                {
                    rebindViewAtIndexPath(indexPath.indexPath, toViewModel: new.viewModel)
                } else {
                    indexPathsToReload.append(indexPath.indexPath)
                }
            }

            if !indexPathsToReload.isEmpty {
                collectionView.reloadItems(at: indexPathsToReload)
            }
        }
    }

    private func rebindViewAtIndexPath(_ indexPath: IndexPath, toViewModel viewModel: ViewModel) {
        guard let collectionView = collectionView else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewHostCell else { return }

        willRebindViewModel(viewModel)
        cell.hostedView?.rebindToViewModel(viewModel)
    }

    // MARK: UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch collectionViewState {
        case .loading:
            _ = currentCollection.update(underlyingCollection)
            collectionViewState = .synced
        default:
            break
        }
        return currentCollection.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        precondition(collectionViewState != .loading)
        if currentCollection.sections.indices.contains(section) {
            return currentCollection.sections[section].count
        }
        return 0
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        precondition(collectionViewState != .loading)
        // Fetch the model item and view model.
        let modelItem = currentCollection.sections[indexPath.section][indexPath.item]
        var cachedViewModel = self.cachedViewModel(for: modelItem)
        let viewModel = cachedViewModel.viewModel

        // Get the view class that will bind to the view model.
        let viewType = viewBinder.viewTypeForViewModel(viewModel, context: context)

        // Register the view/model pair to optimize reuse.
        let reuseId = reuseIdProvider.reuseIdForViewModel(viewModel, viewType: viewType)
        collectionView.register(CollectionViewHostCell.self, forCellWithReuseIdentifier: reuseId)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath)
        cell.backgroundColor = collectionViewBackgroundColor

        if let hostCell = cell as? CollectionViewHostCell {
            var reuseView: View?

            // Determine if there is already a hosted view that matches the view class - if so, it can be reused as is.
            if let hostUIView = hostCell.hostedView as? UIView , type(of: hostUIView) == viewType {
                reuseView = hostCell.hostedView
            }

            // Bust the layout cache if it's stale.
            if let layout = cachedViewModel.preferredLayout.layout , !layout.validCache(forViewModel: viewModel) {
                // TODO:(danielh) This has the same issue as the update where it assumes available size.
                let maxSize = CGSize(width: collectionView.bounds.width, height: CGSize.maxWindowSize.height)
                let availableSize = AvailableSize(maxSize)
                cachedViewModel.preferredLayout = viewBinder.preferredLayout(
                    fitting: availableSize,
                    for: viewModel,
                    context: context)
                viewModelCache[modelItem.modelId] = cachedViewModel
            }

            let view = viewBinder.view(
                for: viewModel,
                context: context,
                reusing: reuseView,
                layout: cachedViewModel.preferredLayout.layout)

            hostCell.hostedView = view
        }
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let supplementaryViewBinder = supplementaryViewBinderMap[kind] else {
            Log.fatal(message: "Request for supplementary kind (\(kind)) that has no registered view binder.")
        }

        let viewModel = viewModelForSupplementaryElementAtIndexPath(kind, indexPath: indexPath)
        let viewType = supplementaryViewBinder.viewTypeForViewModel(viewModel, context: context)
        let reuseId = reuseIdProvider.reuseIdForViewModel(viewModel, viewType: viewType)

        collectionView.register(
            CollectionViewHostReusableView.self,
            forSupplementaryViewOfKind: kind,
            withReuseIdentifier: reuseId)

        let supplementaryView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: reuseId,
            for: indexPath)

        if let supplementaryView = supplementaryView as? CollectionViewHostReusableView {
            var reuseView: View?
            if let hostUIView = supplementaryView.hostedView as? UIView , type(of: hostUIView) == viewType {
                reuseView = supplementaryView.hostedView
            }
            let view = supplementaryViewBinder.view(
                for: viewModel, context: context, reusing: reuseView, layout: nil)
            supplementaryView.hostedView = view
        }

        return supplementaryView
    }
}


// MARK: - macOS Data and Batch Updates

#elseif os(OSX)

private struct OSInfo {
    static let isAtLeastSierra: Bool = {
        let sierra = OperatingSystemVersion(majorVersion: 10, minorVersion: 12, patchVersion: 0)
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(sierra)
    }()
}

private class EmptyCollectionViewItem: NSCollectionViewItem {
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder: NSCoder) {
        Log.fatal(message: "Unsupported initializer")
    }

    override func loadView() {
        view = NSView(frame: .zero)
    }
}

extension CollectionViewModelDataSource: NSCollectionViewDataSource {

    // MARK: Private

    public func handleUpdateItems(_ updates: CollectionEventUpdates, completion: @escaping () -> Void) {
        // preconditions
        precondition(collectionViewState == .synced) // but not for long!
        precondition(updates.hasUpdates)
        guard let collectionView = collectionView else {
            Log.fatal(message: "handleUpdateItems should never run without a collectionView")
        }
        // The standard collection view hierarchy is `NSScrollView`->`NSClipView`->`NSCollectionView`, so finding
        // the scroll view via super view chaining is expected.
        guard let scrollView = collectionView.superview?.superview as? NSScrollView else {
            Log.fatal(message: "CollectionViewModelDataSource requires an outer scrollview.")
        }

        log(event: "HandleUpdateItems", updates: updates)

        let didProcessUpdatesWithLog: (CollectionEventUpdates) -> Void = { [weak self] updates in
            self?.log(event: "DidProcessUpdates", updates: updates)
            completion()
        }

        let invalidatedViewModelCache = invalidateViewModelCache(for: updates)

        if shouldPerformFullReload(withCollectionView: collectionView, scrollView: scrollView, updates: updates) {
            guard !OSInfo.isAtLeastSierra else {
                let oldSectionCount = collectionView.numberOfSections
                let newSectionCount = numberOfSections(in: collectionView)
                precondition(Thread.isMainThread)
                collectionViewState = .animating
                collectionView.performBatchUpdates({
                    precondition(Thread.isMainThread)
                    let existingSections = IndexSet(integersIn: 0..<oldSectionCount)
                    collectionView.deleteSections(existingSections)
                    collectionView.insertSections(IndexSet(integersIn: 0..<newSectionCount))
                }, completionHandler: { [weak self] _ in
                    precondition(Thread.isMainThread)
                    didProcessUpdatesWithLog(updates)
                    self?.advanceCollectionViewStateAfterPerformUpdates()
                })
                return
            }

            // CollectionView.reloadData does not synchronously fetch new information from the data source, so
            // don't call performBatchUpdates until it does.
            collectionViewState = .loading
            collectionView.reloadData()

            //precondition(collectionViewState != .loading)

            // NOTE: This notifies observers of .didUpdateItems before the CollectionView has been updated.
            // Presumably this means code that tries to preserve selection across changes will not work if a reload
            // is triggered.  One option would be to wait until the CollectionView asks for the section count and
            // fire the .didUpdateItems event then, but if the CollectionView is hidden that may not happen.
            // Not sure what the best option is, besides complaining about how hard it is to use CollectionView.
            // Another option: trigger a different event type indicating a reload has started.
            didProcessUpdatesWithLog(updates)

            return
        }

        // Determine if this should be animated.
        let shouldAnimate = shouldAnimateUpdates(updates)

        if shouldAnimate {
            // BUGFIX: If the collection view is deallocated during the timespan of the animation, NSCollectionView
            // internals will end up calling the non-zeroing weak delegate back and crashing. So retain both the
            // delegate and the collection view until the animation completes.
            // This is easy to repro by removing the completion handler and increasing the animation duration.
            let retainedDelegate = collectionView.delegate
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.completionHandler =  { [collectionView, retainedDelegate] in
                _ = collectionView
                _ = retainedDelegate
            }
            NSAnimationContext.current.duration = 0.2
        }

        // `performBatchUpdates` doesn't animate away deletes, so as a workaround the deleted items are set to
        // alpha of 0 and then restored at the end of the batch.
        // TODO(wkiefer): There's likely a better solution here, but not fading them out looks bad.
        var forceHiddenItems: [NSCollectionViewItem] = []

        collectionViewState = .animating

        let cv = shouldAnimate ? collectionView.animator() : collectionView
        cv.performBatchUpdates({
            // Note: The ordering below is important and should not change. See note in
            // `CollectionEventUpdates`

            let removedSections = updates.removedSections
            if !removedSections.isEmpty {
                collectionView.deleteSections(IndexSet(removedSections))
            }

            let addedSections = updates.addedSections
            if !addedSections.isEmpty {
                collectionView.insertSections(IndexSet(addedSections))
            }

            let removed = updates.removedModelPaths
            if !removed.isEmpty {
                let removedIndexPathSet = Set(removed.map { $0.indexPath })
                let visibleIndexPaths = collectionView.indexPathsForVisibleItems()

                // Workaround for `NSCollectionView` not removing the items until the end.
                for indexPath in removedIndexPathSet.intersection(visibleIndexPaths) {
                    if let item = collectionView.item(at: indexPath) {
                        item.view.alphaValue = 0
                        forceHiddenItems.append(item)
                    }
                }

                collectionView.deleteItems(at: removedIndexPathSet)
            }
            let added = updates.addedModelPaths
            if !added.isEmpty {
                collectionView.insertItems(at: Set(added.map { $0.indexPath } ))
            }
            let movedModels = updates.movedModelPaths
            if !movedModels.isEmpty {
                let usingFakeMoves = shouldFakeMoves(updates: updates)
                for move in movedModels {
                    if usingFakeMoves {
                        collectionView.deleteItems(at: [move.from.indexPath])
                        collectionView.insertItems(at: [move.to.indexPath])
                    } else {
                        collectionView.moveItem(at: move.from.indexPath, to: move.to.indexPath)
                    }
                }
            }
        }) { [weak self] (finished: Bool) in
            // Restore alpha on item views.
            forceHiddenItems.forEach { $0.view.animator().alphaValue = 1.0 }

            didProcessUpdatesWithLog(updates)

            self?.advanceCollectionViewStateAfterPerformUpdates()
        }

        // Note that reloads are done outside of the batch update call because they're basically unsupported
        // alongside other complicated batch updates. Because reload actually does a delete and insert under
        // the hood, the collectionview will throw an exception if that index path is touched in any other way.
        // Splitting the call out here ensures this is avoided.
        let updated = updates.updatedModelPaths
        if !updated.isEmpty {
            var reloadSet = Set<IndexPath>()
            let size = collectionView.bounds
            for indexPath in updated {
                var oldCachedViewModel: CachedViewModel?
                var newCachedViewModel: CachedViewModel?

                // Create new view models from the updated models.
                if let model: Model = currentCollection.atModelPath(indexPath) {
                    oldCachedViewModel = invalidatedViewModelCache[model.modelId]

                    _ = cachedViewModel(for: model)

                    // Update the size.
                    // TODO:(wkiefer) Probably should cache last known available size - this makes some assumptions
                    // about available size.
                    let availableSize = AvailableSize(CGSize(width: size.width, height: CGSize.maxWindowSize.height))
                    _ = preferredLayoutForItemAtIndexPath(indexPath.indexPath, availableSize: availableSize)

                    newCachedViewModel = viewModelCache[model.modelId]
                }

                // If the size hasn't changed, simply rebind the view rather than perform a full cell reload.
                if
                    let old = oldCachedViewModel,
                    let new = newCachedViewModel,
                    type(of: old.viewModel) == type(of: new.viewModel) &&
                    old.preferredLayout == new.preferredLayout
                {
                    rebindViewAtIndexPath(indexPath.indexPath, toViewModel: new.viewModel)
                } else {
                    reloadSet.insert(indexPath.indexPath)
                }
            }

            if !reloadSet.isEmpty {
                collectionView.reloadItems(at: reloadSet)
            }
        }

        if shouldAnimate {
            NSAnimationContext.endGrouping()
        }
    }

    private func log(event: String, updates: CollectionEventUpdates) {
        /*
        // Accessing the CollectionView here causes it to query the data source which trips some invariant checks.
        // Sierra calls numberOfItemsInSection before numberOfSections ???
        let collectionViewStatus: String = {
            if let collectionView = collectionView {
                let sectionCounts = (0..<collectionView.numberOfSections).map {
                    collectionView.numberOfItems(inSection: $0)
                }
                return "Sections: \(sectionCounts) Bounds: \(collectionView.bounds)"
            } else {
                return "nil"
            }
        }()
        Log.verbose("pilot.ui", message: "\(event) View \(collectionViewStatus)")
        let modelStatus: String = {
            let sectionCounts = currentCollection.sections.map { $0.count }
            return "Sections: \(sectionCounts)"
        }()
        Log.verbose("pilot.ui", message: "\(event) Model(\(currentCollection.collectionId)) \(modelStatus)")
        let describe: ([ModelPath]) -> String = { paths in
            if paths.isEmpty { return "None" }
            return paths.map({ return "(\($0.sectionIndex), \($0.itemIndex))" }).joined(separator: ",")
        }
        let addedSections = updates.addedSections
            .map { String($0) }
            .joined(separator: ",")
        let addedItems = updates.addedModelPaths
        let movedFrom = updates.movedModelPaths.map { $0.from }
        let movedTo = updates.movedModelPaths.map { $0.to }
        let updateDescription = [
            "AddedSections: [\(addedSections)]",
            "Added: [\(describe(addedItems))]",
            "Updated: [\(describe(updates.updatedModelPaths))]",
            "Removed: [\(describe(updates.removedModelPaths))]",
            "Moved: [(\(describe(movedFrom))) > (\(describe(movedTo)))]"
        ].joined(separator: " ")
        precondition(Thread.isMainThread)
        Log.verbose("pilot.ui", message: "\(event) Updates \(updateDescription)")
        */
    }

    private func advanceCollectionViewStateAfterPerformUpdates() {
        switch collectionViewState {
        case .loading:
            Log.fatal(message: "Precondition failure - state cannot transition from animating to loading")
        case .animating:
            collectionViewState = .synced
        case .animatingWithPendingChanges:
            collectionViewState = .synced // applyCurrentDataToCollectionView will update
            applyCurrentDataToCollectionView()
        case .synced:
            Log.fatal(message: "Precondition failure - state cannot transition from animating to synced")
        }

    }

    private func rebindViewAtIndexPath(_ indexPath: IndexPath, toViewModel viewModel: ViewModel) {
        guard let collectionView = collectionView else { return }
        guard let item = collectionView.item(at: indexPath) as? CollectionViewHostItem else { return }

        willRebindViewModel(viewModel)
        item.hostedView?.rebindToViewModel(viewModel)
    }

    private func shouldFakeMoves(updates: CollectionEventUpdates) -> Bool {
        if updates.movedModelPaths.isEmpty {
            return false
        }
        // NSCollectionView throws an exception when moveItem is called with a `to` IndexPath that is the
        // last item in a different section than the `from`, instead of catching this specific case, all
        // moves across sections do a delete and an insert.
        for move in updates.movedModelPaths {
            if move.from.sectionIndex != move.to.sectionIndex {
                return true
            }
        }

        // If there are any other updates, always perform a delete and insert to avoid invalid index path
        // exception
        // TODO:(danielh) Followup with more investigation on the underlying NSCollectionView problem and try to
        // come up with better fix
        var updatesWithoutMoved = updates
        updatesWithoutMoved.movedModelPaths = []
        return updatesWithoutMoved.hasUpdates
    }

    private func shouldPerformFullReload(
        withCollectionView collectionView: NSCollectionView,
        scrollView: NSScrollView,
        updates: CollectionEventUpdates
    ) -> Bool {
        // If no window, fallback on full reload.
        if collectionView.window == nil {
            return true
        }

        // If `NoneReloadOnly` is specified, always reload.
        if case .noneReloadOnly = updateAnimationStyle {
            return true
        }

        // `performBatchUpdates` will segfault if called on a collectionview with no height or width, so
        // reload in that case.
        let insets = scrollView.contentInsets
        var size = collectionView.collectionViewLayout?.collectionViewContentSize ?? NSSize.zero

        size.height -= insets.top + insets.bottom
        size.width -= insets.left + insets.right
        if size.height < 1.0 || size.width < 1.0 {
            return true
        }

        // If no sections, just reload.  Fixes a segfault messaging a dead object in performBatchUpdates.
        if currentCollection.sections.count == 0 {
            return true
        }

        // If adding first item or removing last item, reload to avoid a crash in NSCollectionView.
        // macOS 10.12 will crash when removing the last item, and sometimes a crash will occur in layout
        // when adding the first item.
        return updates.containsFirstAddInSection || updates.containsLastRemoveInSection
    }

    // MARK: NSCollectionViewDataSource

    private func syncData() {
        switch collectionViewState {
        case .loading:
            currentCollection.update(underlyingCollection)
            collectionViewState = .synced
        default:
            break
        }
    }

    public func numberOfSections(in collectionView: PlatformCollectionView) -> Int {
        syncData()
        return currentCollection.sections.count
    }

    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        /// HACK: Sierra sometimes calls numberOfItemsInSection before numberOfSections, so sync the data in this case too.
        syncData()
        if currentCollection.sections.indices.contains(section) {
            return currentCollection.sections[section].count
        }
        return 0
    }

    public func collectionView(
        _ collectionView: NSCollectionView,
        viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind,
        at indexPath: IndexPath
    ) -> NSView {
        guard let supplementaryViewBinder = supplementaryViewBinderMap[kind.rawValue] else {
            Log.fatal(message: "Request for supplementary kind (\(kind.rawValue)) that has no registered view binder.")
        }

        let viewModel = viewModelForSupplementaryElementAtIndexPath(kind.rawValue, indexPath: indexPath)
        let viewType = supplementaryViewBinder.viewTypeForViewModel(viewModel, context: context)
        let reuseId = reuseIdProvider.reuseIdForViewModel(viewModel, viewType: viewType)

        collectionView.register(
            CollectionViewHostReusableView.self,
            forSupplementaryViewOfKind: kind,
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: reuseId))

        let supplementaryView = collectionView.makeSupplementaryView(
            ofKind: kind,
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: reuseId),
            for: indexPath as IndexPath)

        if let supplementaryView = supplementaryView as? CollectionViewHostReusableView {
            var reuseView: View?
            if let hostView = supplementaryView.hostedView as? NSView , type(of: hostView) == viewType {
                reuseView = supplementaryView.hostedView
            }
            let view = supplementaryViewBinder.view(
                for: viewModel,
                context: context,
                reusing: reuseView,
                layout: nil)
            supplementaryView.hostedView = view
        }

        return supplementaryView
    }

    public func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        precondition(collectionViewState != .loading)

        // Fetch the model item and view model.
        let sections = currentCollection.sections
        guard let modelItem = sections[safe: indexPath.section]?[safe: indexPath.item] else {
            // NSCollectionView occasionally asks for an item outside of the current collection.
            // In that case, return a zero-size view and hope NSCollectionView refreshes itself later.
            // TODO:(ca) dig into this scenario for real and file a radar issue upstream
            return EmptyCollectionViewItem()
        }
        var cachedViewModel = self.cachedViewModel(for: modelItem)
        let viewModel = cachedViewModel.viewModel

        // Get the view class that will bind to the view model.
        let viewType = viewBinder.viewTypeForViewModel(viewModel, context: context)

        // Register the view/model pair to optimize reuse.
        let reuseId = reuseIdProvider.reuseIdForViewModel(viewModel, viewType: viewType)
        collectionView.register(CollectionViewHostItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: reuseId))

        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: reuseId), for: indexPath)

        if let hostItem = item as? CollectionViewHostItem {
            var reuseView: View?

            // Determine if there is already a hosted view that matches the view class - if so, it can be reused as is.
            if let hostUIView = hostItem.hostedView as? NSView , type(of: hostUIView) == viewType {
                reuseView = hostItem.hostedView
            }

            // Bust the layout cache if its stale.
            if let layout = cachedViewModel.preferredLayout.layout , !layout.validCache(forViewModel: viewModel) {
                // TODO:(danielh) This has the same issue as the update where it assumes available size.
                let maxSize = CGSize(width: collectionView.bounds.width, height: CGSize.maxWindowSize.height)
                let availableSize = AvailableSize(maxSize)
                cachedViewModel.preferredLayout = viewBinder.preferredLayout(
                    fitting: availableSize,
                    for: viewModel,
                    context: context)
                viewModelCache[modelItem.modelId] = cachedViewModel
            }

            let view = viewBinder.view(
                for: viewModel,
                context: context,
                reusing: reuseView,
                layout: cachedViewModel.preferredLayout.layout)

            hostItem.hostedView = view
        }
        return item
    }
}
#endif  // os(OSX)

/// Helper struct representing cached data for a `ViewModel`.
private struct CachedViewModel {
    var viewModel: ViewModel
    var preferredLayout: PreferredLayout
}

extension CGSize {
    fileprivate static var maxWindowSize: CGSize {
        // AppKit maximum window size.
        return CGSize(width: 10000, height: 10000)
    }
}
