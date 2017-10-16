import AppKit
import Pilot

/// Struct representing what to display when the collection view is empty.
public enum EmptyCollectionDisplay {
    /// Returns a custom string with font and color, which is displayed in the center of the empty collection view.
    case text(String, NSFont, NSColor)

    /// Returns a custom view that will be centered in the empty collection view.
    case view(NSView)

    /// Returns a custom view and a custom constraint creation block to hook up constraints to the parent view.
    /// Paramaters of the closure are the parent view and the child view, in order. Return value is an
    /// array of constraints which will be added.
    case viewWithCustomConstraints(NSView, (NSView, NSView) -> [NSLayoutConstraint])

    /// No empty view.
    case none
}

/// Struct representing what spinner to display when the collection view is empty and loading.
/// TODO:(wkiefer) Bring this to iOS (and share where possible).
public enum LoadingCollectionDisplay {
    /// No loading view.
    case none

    /// Shows the default system spinner centered in the view.
    case systemSpinner

    /// Shows the default system spinner with the provided custom constraints.
    /// Paramaters of the closure are the parent view and the child view, in order. Return value is an
    /// array of constraints which will be added.
    case systemSpinnerWithConstraints((NSView, NSView) -> [NSLayoutConstraint])

    /// Shows a custom loading indicator view centered in the view.
    case custom(NSView)

    /// Shows a custom loading indicator view with the provided custom constraints.
    /// Paramaters of the closure are the parent view and the child view, in order. Return value is an
    /// array of constraints which will be added.
    case customWithConstraints(NSView, (NSView, NSView) -> [NSLayoutConstraint])
}

/// View controller implementation which contains the core MVVM binding support to show a given `ModelCollection`
/// in a collection view.
/// Subclassing should typically be only for app-specific view controller behavior (and not cell configuration).
open class CollectionViewController: NSViewController, CollectionViewDelegate {

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

        // loadView will never fail
        super.init(nibName: nil, bundle: nil)!
    }

    @available(*, unavailable,
        message: "Use `init(model:modelBinder:viewBinder:layout:context:)`")
    public required init?(coder: NSCoder) {
        Log.fatal(message: "Use `init(model:modelBinder:viewBinder:layout:context:)` instead")
    }

    deinit {
        unreigsterForMenuTrackingEnd()
        unregisterForModelEvents()
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }

    // MARK: Public

    /// Read-only access to the model collection representing the data as far as the CollectionView
    /// has been told. If the current code path is initiated by the CollectionView and uses an IndexPath,
    /// this is the collection that should be used.
    /// See `CollectionViewModelDataSource.currentCollection` for more documentation.
    public var collection: ModelCollection {
        return dataSource.currentCollection
    }

    /// Read-only access to the underlying context.
    public var context: Context {
        return dataSource.context
    }

    /// Read-only access to the collection view data source.
    public let dataSource: CollectionViewModelDataSource

    /// Layout for the collection view.
    open var layout: NSCollectionViewLayout {
        didSet {
            guard isViewLoaded else { return }
            collectionView.collectionViewLayout = layout
        }
    }

    open var backgroundColor = NSColor.clear {
        didSet {
            guard isViewLoaded else { return }
            collectionView.backgroundColors = [backgroundColor]
        }
    }

    /// Read-only access to the underlying collection view.
    open let collectionView: CollectionView = CollectionView()

    /// Read-only access to the underlying scroll view.
    open var scrollView: NSScrollView {
        return internalScrollView
    }

    /// Enables or disables scrolling on the hosted scrollview.
    open var scrollEnabled: Bool {
        get { return internalScrollView.scrollEnabled }
        set { internalScrollView.scrollEnabled = newValue }
    }

    /// Determines what should be displayed for an empty collection that is loading.
    open var loadingDisplay: LoadingCollectionDisplay = .systemSpinner

    // MARK: Public Intended for subclass override

    /// Returns the root view created during `loadView`. Subclasses may override to provide their own customized
    /// view instance.
    open func makeRootView() -> NSView {
        return NSView()
    }

    /// Returns an `EmptyCollectionDisplay` struct defining what to show for an empty collection in the `Error` state.
    /// Intended for subclass override.
    open func displayForErrorState(_ error: Error) -> EmptyCollectionDisplay {
        return .none
    }

    /// Returns an `EmptyCollectionDisplay` struct defining what to show for an empty collection that has no data but
    /// is in the `Loaded` state. Intended for subclass override.
    open func displayForNoContentState() -> EmptyCollectionDisplay {
        return .none
    }

    /// Intended for subclass override - invoked when a model object is displayed in the collection.
    open func willDisplayViewModel(_ viewModel: ViewModel) {
        // NOP - intended for subclassing.
    }

    // MARK: NSViewController

    public final override func loadView() {
        view = makeRootView()
        view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]

        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]

        scrollView.wantsLayer = true
        scrollView.layerContentsRedrawPolicy = .onSetNeedsDisplay

        scrollView.horizontalScroller = FullWidthScroller()
        scrollView.verticalScroller = FullWidthScroller()

        scrollView.documentView = collectionView
        scrollView.drawsBackground = false
        scrollView.contentView.copiesOnScroll = true

        collectionView.wantsLayer = true
        collectionView.layerContentsRedrawPolicy = .onSetNeedsDisplay

        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColors = [backgroundColor]
        collectionView.itemPrototype = nil
        collectionView.isSelectable = true
        collectionView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
    }

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
        registerForModelEvents()
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
        modifiers: NSEvent.ModifierFlags
    ) -> Bool {
        guard let indexPath = collectionView.selectionIndexPaths.first else { return false }
        guard let vm = viewModelAtIndexPath(indexPath) else { return false }
        let event = ViewModelUserEvent.keyDown(key, modifiers.eventKeyModifierFlags)
        if vm.canHandleUserEvent(event) {
            vm.handleUserEvent(event)
            return true
        }
        return false
    }

    open func collectionView(_ collectionView: NSCollectionView, didClickIndexPath indexPath: IndexPath) {
        guard let vm = viewModelAtIndexPath(indexPath) else { return }
        if vm.canHandleUserEvent(.click) {
            vm.handleUserEvent(.click)
        }
    }

    open func collectionView(_ collectionView: NSCollectionView, menuForIndexPath indexPath: IndexPath) -> NSMenu? {
        guard let vm = viewModelAtIndexPath(indexPath) else { return nil }

        if vm.canHandleUserEvent(.secondaryClick) {
            vm.handleUserEvent(.secondaryClick)

            let actions = vm.secondaryActions(for: .secondaryClick)
            if !actions.isEmpty {
                let menu = NSMenu.fromSecondaryActions(actions, action: #selector(didSelectContextMenuItem(_:)))
                if let item = collectionView.item(at: indexPath) as? CollectionViewHostItem {
                    item.highlightStyle = .contextMenu
                    registerForMenuTrackingEnd(menu, item: item)
                }
                return menu
            }
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

    // MARK: Private

    private var lastBounds = CGRect.zero
    private let internalScrollView = FullWidthScrollView()

    private func viewModelAtIndexPath(_ indexPath: IndexPath) -> ViewModel? {
        guard let item = collectionView.item(at: indexPath as IndexPath) as? CollectionViewHostItem else { return nil}
        return item.hostedView?.viewModel
    }

    /// View to show when in the `loading` state - dictated by `loadingDisplay`.
    private var loadingView: NSView?

    private func showLoadingView() {
        guard self.loadingView == nil else { return }
        guard let loadingView = loadingView(for: loadingDisplay) else { return }

        self.loadingView = loadingView

        loadingView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(loadingView)

        let makeConstraints = loadingViewConstraints(for: loadingDisplay)
        NSLayoutConstraint.activate(makeConstraints(view, loadingView))
    }

    private func hideLoadingView() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    private func loadingView(for display: LoadingCollectionDisplay) -> NSView? {
        switch display {
        case .none:
            return nil
        case .custom(let view):
            return view
        case .customWithConstraints(let view, _):
            return view
        case .systemSpinnerWithConstraints(_):
            fallthrough
        case .systemSpinner:
            let spinner = NSProgressIndicator()
            spinner.style = .spinningStyle
            spinner.controlSize = .small
            spinner.startAnimation(self)
            return spinner
        }
    }

    private func loadingViewConstraints(
        for display: LoadingCollectionDisplay
    ) -> (NSView, NSView) -> [NSLayoutConstraint] {
        let defaultConstraints: (NSView, NSView) -> [NSLayoutConstraint] = { parent, child in
            return [child.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
                    child.centerYAnchor.constraint(equalTo: parent.centerYAnchor),
                    child.bottomAnchor.constraint(lessThanOrEqualTo: parent.bottomAnchor),
                    child.topAnchor.constraint(greaterThanOrEqualTo: parent.topAnchor)]
        }

        switch display {
        case .custom(_):
            return defaultConstraints
        case .customWithConstraints(_, let constraints):
            return constraints
        case .none:
            return { _, _ in return [] }
        case .systemSpinner:
            return defaultConstraints
        case .systemSpinnerWithConstraints(let constraints):
            return constraints
        }
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
        unreigsterForMenuTrackingEnd()

        let cookie = item.menuTrackingCookie

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSMenuDidEndTracking,
            object: menu,
            queue: OperationQueue.main) { [weak item] _ in
                guard let item = item , item.menuTrackingCookie == cookie else { return }
                item.highlightStyle = .none

        }
    }

    private var menuNotificationObserver: NSObjectProtocol?
    private func unreigsterForMenuTrackingEnd() {
        guard let menuNotificationObserver = self.menuNotificationObserver else { return }
        NotificationCenter.default.removeObserver(menuNotificationObserver)
        self.menuNotificationObserver = nil
    }

    // MARK: Observing model state changes.

    private var collectionObserver: Observer?

    private func registerForModelEvents() {
        assertWithLog(collectionObserver == nil, message: "Expected to start with a nil token")

        collectionObserver = collection.observe { [weak self] event in
            self?.handleModelEvent(event)
        }

        // Upon registering, fire an initial state change to match existing state.
        handleModelEvent(.didChangeState(collection.state))
    }

    private func unregisterForModelEvents() {
        collectionObserver = nil
    }

    private func handleModelEvent(_ event: CollectionEvent) {
        hideEmptyContentView()

        switch event {
        case .didChangeState(let state):
            if !state.isLoading {
                // Non-loading states should hide the spinner.
                hideLoadingView()
            }

            switch state {
            case .notLoaded:
                break
            case .loading(let models):
                if models == nil || state.isEmpty {
                    showLoadingView()
                }
            case .loaded:
                updateEmptyContentViewVisibility()
            case .error(_):
                updateEmptyContentViewVisibility()
            }
        }
    }

    /// View which is displayed when there is no content (either due to error or lack of loaded data).
    private var emptyContentView: NSView?

    private func showEmptyContentView() {
        guard self.emptyContentView == nil else { return }

        let display: EmptyCollectionDisplay
        if case .error(let error) = collection.state {
            display = displayForErrorState(error)
        } else {
            display = displayForNoContentState()
        }

        if let emptyContentView = emptyContentView(for: display) {
            self.emptyContentView = emptyContentView

            emptyContentView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyContentView)

            let makeConstraints = emptyContentViewConstraints(for: display)
            NSLayoutConstraint.activate(makeConstraints(view, emptyContentView))
        }
    }

    private func hideEmptyContentView() {
        emptyContentView?.removeFromSuperview()
        emptyContentView = nil
    }

    private func updateEmptyContentViewVisibility() {
        switch collection.state {
        case .error(_), .loaded:
            if collection.isEmpty {
                showEmptyContentView()
            } else {
                hideEmptyContentView()
            }
        case .notLoaded, .loading:
            hideEmptyContentView()
        }
    }

    private func emptyContentView(for display: EmptyCollectionDisplay) -> NSView? {
        switch display {
        case .none:
            return nil
        case .text(let string, let font, let color):
            let label = NSTextField()
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = .clear
            label.alignment = .center
            label.font = font
            label.textColor = color
            label.stringValue = string
            return label
        case .viewWithCustomConstraints(let view, _):
            return view
        case .view(let view):
            return view
        }
    }

    private func emptyContentViewConstraints(
        for display: EmptyCollectionDisplay
    ) -> (NSView, NSView) -> [NSLayoutConstraint] {
        switch display {
        case .viewWithCustomConstraints(_, let constraints):
            return constraints
        case .text(_, _, _):
            return { parent, child in
                return [child.widthAnchor.constraint(equalTo: parent.widthAnchor),
                        child.heightAnchor.constraint(lessThanOrEqualTo: parent.widthAnchor),
                        child.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
                        child.centerYAnchor.constraint(equalTo: parent.centerYAnchor)]
            }
        default:
            return { parent, child in
                return [child.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
                        child.centerYAnchor.constraint(equalTo: parent.centerYAnchor)]
            }
        }
    }
}

// MARK: -

/// Private helper class to force the scroller to always appear as a modern over-content scroller.
private final class FullWidthScroller: NSScroller {

    // MARK: NSScroller

    override class func isCompatibleWithOverlayScrollers() -> Bool {
        return true
    }

    override class func preferredScrollerStyle() -> NSScrollerStyle {
        return .overlay
    }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Nop
    }

    override class func scrollerWidth(
        for controlSize: NSControlSize,
        scrollerStyle: NSScrollerStyle
    ) -> CGFloat {
        if FullWidthScroller.widthOverride {
            return 0.0
        }
        return super.scrollerWidth(for: controlSize, scrollerStyle: scrollerStyle)
    }

    // MARK: Private

    static var widthOverride = false
}

/// Private helper class to force the vertical scroller to always appear as a modern over-content scroller.
fileprivate final class FullWidthScrollView: NSScrollView {

    fileprivate var scrollEnabled: Bool = true

    // MARK: NSScrollView

    fileprivate override func scrollWheel(with theEvent: NSEvent) {
        if scrollEnabled {
            super.scrollWheel(with: theEvent)
        }
    }

    fileprivate override func flashScrollers() {
        if scrollEnabled {
            super.flashScrollers()
        }
    }

    fileprivate override func tile() {
        // For the superclass's tile implementation, the scroller returns zero width so content underneath is always
        // full width.
        FullWidthScroller.widthOverride = true
        super.tile()
        FullWidthScroller.widthOverride = false

        guard let verticalScroller = verticalScroller else { return }

        // Now adjust the actual scroller frame since the `super.tile()` call made it zero width.
        let bounds = self.bounds
        let vInset = contentInsets
        let vWidth = FullWidthScroller.scrollerWidth(
            for: verticalScroller.controlSize,
            scrollerStyle: verticalScroller.scrollerStyle)
        verticalScroller.frame = CGRect(
            x: bounds.width - vWidth - vInset.right,
            y: vInset.top,
            width: vWidth,
            height: bounds.height - vInset.top - vInset.bottom)
    }
}
