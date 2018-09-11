import AppKit
import Pilot

/// Common view controller to support a scrollable views of a ModelCollection.
///
/// Note: this is open to facilitate subclassing with open classes like CollectionViewController, but isn't intended or
/// useful to subclass this class directly outside of PilotUI.
open class ModelCollectionViewController: NSViewController {

    public init(model: ModelCollection, context: Context) {
        self.model = model
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "Use `init(model:modelBinder:viewBinder:layout:context:)`")
    public required init?(coder: NSCoder) {
        Log.fatal(message: "Use `init(model:modelBinder:viewBinder:layout:context:)` instead")
    }

    deinit {
        unregisterForModelEvents()
    }

    // MARK: Open functions for subclasses to customize.

    /// Determines what should be displayed for an empty collection that is loading.
    open var loadingDisplay: LoadingCollectionDisplay = .systemSpinner

    /// Returns the root view created during `loadView`. Subclasses may override to provide their own customized
    /// view instance.
    open func makeRootView() -> NSView {
        return NSView()
    }

    /// Returns the scrollView view created during `loadView`. Subclasses may override to provide their own customized
    /// scrollView instance.
    open func makeScrollView() -> NSScrollView {
        return FullWidthScrollView()
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

    /// Read-only access to the underlying scroll view.
    open var scrollView: NSScrollView {
        if let scrollView = internalScrollView { return scrollView }

        let scrollView = makeScrollView()
        internalScrollView = scrollView
        return scrollView
    }

    /// Enables or disables scrolling on the hosted scrollview iff it's a NestableScrollView.
    open var scrollEnabled: Bool {
        get {
            guard let scrollView = scrollView as? NestableScrollView else { return false }
            return scrollView.scrollEnabled
        }
        set {
            guard let scrollView = scrollView as? NestableScrollView else { return }
            scrollView.scrollEnabled = newValue
        }
    }

    // MARK: Public

    public let model: ModelCollection
    public let context: Context

    // MARK: NSViewController

    public final override func loadView() {
        view = makeRootView()
        view.autoresizingMask = [.width, .height]

        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.width, .height]

        scrollView.wantsLayer = true
        scrollView.layerContentsRedrawPolicy = .onSetNeedsDisplay

        scrollView.horizontalScroller = FullWidthScroller()
        scrollView.verticalScroller = FullWidthScroller()

        scrollView.documentView = makeDocumentView()
        scrollView.drawsBackground = false
        scrollView.contentView.copiesOnScroll = true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        registerForModelEvents()
    }

    /// Intended to be overridden by subclass. Returns the documentView of the scrollView, called once during loadView.
    // TODO:(danielh) This should be able to be internal, but linking fails on release builds when it is, file radar.
    public func makeDocumentView() -> NSView {
        return NSView()
    }

    // MARK: Private

    private var internalScrollView: NSScrollView?

    /// View which is displayed when there is no content (either due to error or lack of loaded data).
    private var emptyContentView: NSView?

    private func showEmptyContentView() {
        guard self.emptyContentView == nil else { return }

        let display: EmptyCollectionDisplay
        if case .error(let error) = model.state {
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
        switch model.state {
        case .error, .loaded:
            if model.state.isEmpty {
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

    /// View to show when in the `loading` state - dictated by `loadingDisplay`.
    private var loadingView: NSView?

    private func showLoadingView() {
        guard self.loadingView == nil else { return }
        guard let loadingView = loadingView(for: loadingDisplay) else { return }

        self.loadingView = loadingView

        loadingView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView?.addSubview(loadingView)

        let makeConstraints = loadingViewConstraints(for: loadingDisplay)
        NSLayoutConstraint.activate(makeConstraints(view, loadingView))
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
            spinner.style = .spinning
            spinner.controlSize = .small
            spinner.startAnimation(self)
            return spinner
        }
    }

    // MARK: Observing model state changes.

    private var collectionObserver: Subscription?

    private func registerForModelEvents() {
        assertWithLog(collectionObserver == nil, message: "Expected to start with a nil token")

        collectionObserver = model.observeValues { [weak self] event in
            self?.handleModelEvent(event)
        }

        // Upon registering, fire an initial state change to match existing state.
        handleModelEvent(.didChangeState(model.state))
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
}

// MARK: -

/// Private helper class to force the scroller to always appear as a modern over-content scroller.
private final class FullWidthScroller: NSScroller {

    // MARK: NSScroller

    override class var isCompatibleWithOverlayScrollers: Bool {
        return true
    }

    override class var preferredScrollerStyle: NSScroller.Style {
        return .overlay
    }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Nop
    }

    override class func scrollerWidth(
        for controlSize: NSControl.ControlSize,
        scrollerStyle: NSScroller.Style
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
private final class FullWidthScrollView: NestableScrollView {

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
