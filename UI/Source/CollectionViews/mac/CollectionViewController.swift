import AppKit
import Pilot

/// View controller implementation which contains the core MVVM binding support to show a given `ModelCollection`
/// in a collection view.
/// Subclassing should typically be only for app-specific view controller behavior (and not cell configuration).
open class CollectionViewController: ModelCollectionViewController, CollectionViewDelegate {

    // MARK: Init

    public init(
        model: ModelCollection,
        modelBinder: ViewModelBindingProvider,
        viewBinder: ViewBindingProvider,
        layout: NSCollectionViewLayout,
        context: Context,
        reuseIdProvider: CollectionViewCellReuseIdProvider = DefaultCollectionViewCellReuseIdProvider()
    ) {
        self.layout = layout
        self.dataSource = CollectionViewModelDataSource(
            model: model,
            modelBinder: modelBinder,
            viewBinder: viewBinder,
            context: context.newScope(),
            reuseIdProvider: reuseIdProvider)
        self.modelBinder = modelBinder
        super.init(model: dataSource.currentCollection, context: dataSource.context)
    }

    deinit {
        unregisterForMenuTrackingEnd()
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }

    // MARK: Public

    /// Read-only access to the model collection representing the data as far as the CollectionView
    /// has been told. If the current code path is initiated by the CollectionView and uses an IndexPath,
    /// this is the collection that should be used.
    /// See `CollectionViewModelDataSource.currentCollection` for more documentation.
    public var collection: SectionedModelCollection {
        return dataSource.currentCollection
    }

    /// Read-only access to the collection view data source.
    public let dataSource: CollectionViewModelDataSource

    public func model(at indexPath: IndexPath) -> Model {
        return dataSource.currentCollection.sections[indexPath.section][indexPath.item]
    }

    /// Layout for the collection view.
    open var layout: NSCollectionViewLayout {
        didSet {
            guard isViewLoaded else { return }
            collectionView.collectionViewLayout = layout
            // Workaround for a 10.13 bug where the NSCollectionView frame is not updated when it's layout is changed.
            // See https://stackoverflow.com/questions/46433652/nscollectionview-does-not-scroll-items-past-initial-visible-rect?rq=1
            if #available(OSX 10.13, *) {
                if let contentSize = collectionView.collectionViewLayout?.collectionViewContentSize {
                    collectionView.setFrameSize(contentSize)
                }
            }
        }
    }

    open var backgroundColor = NSColor.clear {
        didSet {
            guard isViewLoaded else { return }
            collectionView.backgroundColors = [backgroundColor]
        }
    }

    /// Read-only access to the underlying collection view.
    public let collectionView: CollectionView = CollectionView()

    /// Access to the current view model of selected items.
    public var selectionViewModel: SelectionViewModel? {
        guard !collectionView.selectionIndexPaths.isEmpty else { return nil }
        let selectedModels = collectionView.selectionIndexPaths.map { model(at: $0) }
        return modelBinder.selectionViewModel(for: selectedModels, context: context)
    }

    // MARK: ModelCollectionViewController

    public final override func makeDocumentView() -> NSView {
        collectionView.wantsLayer = true
        collectionView.layerContentsRedrawPolicy = .onSetNeedsDisplay

        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColors = [backgroundColor]
        collectionView.itemPrototype = nil
        collectionView.isSelectable = true
        collectionView.autoresizingMask = [.width, .height]
        return collectionView
    }

    // MARK: NSViewController

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.layer?.backgroundColor = NSColor.clear.cgColor

        dataSource.collectionView = collectionView

        collectionView.collectionViewLayout = layout
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.layer?.backgroundColor = NSColor.clear.cgColor

        dataSource.willRebindViewModel = { [weak self] viewModel in
            self?.willDisplayViewModel(viewModel)
        }

        scrollView.scrollerStyle = .overlay

        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(doubleClick(_:)))
        recognizer.numberOfClicksRequired = 2
        // Don't delay single-click waiting for double-click failure.
        recognizer.delaysPrimaryMouseButtonEvents = false
        collectionView.addGestureRecognizer(recognizer)
    }

    open override func viewWillLayout() {
        super.viewWillLayout()

        let bounds = view.bounds
        if !bounds.equalTo(lastBounds) {
            dataSource.clearCachedItemSizes()
        }
        lastBounds = bounds
    }

    // MARK: CollectionViewDelegate

    open func collectionViewDidReceiveKeyEvent(
        _ collectionView: NSCollectionView,
        key: EventKeyCode,
        modifiers: AppKitEventModifierFlags,
        timestamp: TimeInterval,
        characters: String?
    ) -> Bool {
        let event = ViewModelUserEvent.keyDown(key, modifiers.eventKeyModifierFlags, characters)
        return handleUserEvent(event)
    }

    open func collectionView(_ collectionView: NSCollectionView, didClickIndexPath indexPath: IndexPath) {
        guard let vm = viewModelAtIndexPath(indexPath) else { return }

        let modifierFlags = NSApp.currentEvent?.eventKeyModifierFlags ?? []
        let event = ViewModelUserEvent.click(modifierFlags)
        if vm.canHandleUserEvent(event) {
            vm.handleUserEvent(event)
        }
    }

    open func collectionView(_ collectionView: NSCollectionView, menuForIndexPath indexPath: IndexPath) -> NSMenu? {
        // If the event location is inside the current selection, generate menu for the entire current selection.
        // Otherwise, generate menu for the mapped item.
        guard let selection: SelectionViewModel = {
            if collectionView.selectionIndexPaths.contains(indexPath) {
                return selectionViewModel
            }
            return modelBinder.selectionViewModel(for: [model(at: indexPath)], context: context)
        }() else { return nil }

        guard selection.canHandleUserEvent(.secondaryClick) else { return nil }

        selection.handleUserEvent(.secondaryClick)
        let actions = selection.secondaryActions(for: .secondaryClick)

        if !actions.isEmpty {
            let selectedIndexPaths = collectionView.selectionIndexPaths.contains(indexPath) ?
                collectionView.selectionIndexPaths : Set([indexPath])

            let menu = NSMenu.fromSecondaryActions(actions, action: #selector(didSelectContextMenuItem(_:)))
            for indexPath in selectedIndexPaths {
                if let item = collectionView.item(at: indexPath) as? CollectionViewHostItem {
                    item.highlightStyle = .contextMenu
                    registerForMenuTrackingEnd(menu, item: item)
                }
            }
            return menu
        }
        return nil
    }

    // MARK: NSCollectionViewDelegate

    open func collectionView(
        _ collectionView: NSCollectionView,
        willDisplay item: NSCollectionViewItem,
        forRepresentedObjectAt indexPath: IndexPath
    ) {
        guard let viewModel = dataSource.viewModelAtIndexPath(indexPath) else { return }
        willDisplayViewModel(viewModel)
    }

    open func collectionView(
        _ collectionView: NSCollectionView,
        didSelectItemsAt indexPaths: Set<IndexPath>
    ) {
        guard let indexPath = indexPaths.first , indexPaths.count == 1 else { return }
        guard let vm = viewModelAtIndexPath(indexPath) else { return }
        if vm.canHandleUserEvent(.select) {
            vm.handleUserEvent(.select)
        }
    }

    // MARK: NSObject

    open override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(copy(_:)) {
            return selectedViewModel()?.canHandleUserEvent(.copy) == true
        }
        return false
    }

    // MARK: Private

    private var lastBounds = CGRect.zero
    private var modelBinder: ViewModelBindingProvider

    private func viewModelAtIndexPath(_ indexPath: IndexPath) -> ViewModel? {
        guard let item = collectionView.item(at: indexPath as IndexPath) as? CollectionViewHostItem else { return nil}
        return item.hostedView?.viewModel
    }

    private func handleUserEvent(_ event: ViewModelUserEvent) -> Bool {
        guard let selectionViewModel = selectionViewModel else { return false }
        if selectionViewModel.canHandleUserEvent(event) {
            selectionViewModel.handleUserEvent(event)
            return true
        }
        return false
    }

    @objc
    private func didSelectContextMenuItem(_ menuItem: NSMenuItem) {
        guard let action = menuItem.representedAction else {
            Log.warning(message: "No action attached to secondary action menu item: \(menuItem)")
            return
        }
        action.send(from: context)
    }

    private func registerForMenuTrackingEnd(_ menu: NSMenu, item: CollectionViewHostItem) {
        unregisterForMenuTrackingEnd()

        let cookie = item.menuTrackingCookie

        menuNotificationObserver = NotificationCenter.default.addObserver(
            forName: NSMenu.didEndTrackingNotification,
            object: menu,
            queue: OperationQueue.main) { [weak item] _ in
                guard let item = item , item.menuTrackingCookie == cookie else { return }
                item.highlightStyle = .none

        }
    }

    private var menuNotificationObserver: NSObjectProtocol?
    private func unregisterForMenuTrackingEnd() {
        guard let menuNotificationObserver = self.menuNotificationObserver else { return }
        NotificationCenter.default.removeObserver(menuNotificationObserver)
        self.menuNotificationObserver = nil
    }

    private func selectedViewModel() -> ViewModel? {
        guard let indexPath = collectionView.selectionIndexPaths.first else { return nil }
        return viewModelAtIndexPath(indexPath)
    }

    @objc
    private func copy(_ sender: Any) {
        selectedViewModel()?.handleUserEvent(.copy)
    }

    @objc
    private func doubleClick(_ sender: Any) {
        guard let action = selectionViewModel?.actionForUserEvent(.doubleClick) else { return }
        action.send(from: context)
    }
}
