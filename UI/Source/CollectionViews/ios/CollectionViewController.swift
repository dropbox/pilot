import Pilot
import UIKit

/// Struct representing what to display when the collection view is empty.
public enum EmptyCollectionDisplay {
    case text(String, UIFont, UIColor)
    case view(UIView)
    case none
}

/// View controller implementation which contains the core MVVM binding support to show a given `ModelCollection`
/// in a collection view.
/// Subclassing should typically be only for app-specific view controller behavior (and not cell configuration).
open class CollectionViewController: UIViewController, UICollectionViewDelegate {

    // MARK: Init

    public init(
        model: ModelCollection,
        modelBinder: ViewModelBindingProvider,
        viewBinder: ViewBindingProvider,
        layout: UICollectionViewLayout,
        context: Context,
        reuseIdProvider: CollectionViewCellReuseIdProvider = DefaultCollectionViewCellReuseIdProvider()
    ) {
        let dataSource = CollectionViewModelDataSource(
            model: model,
            modelBinder: modelBinder,
            viewBinder: viewBinder,
            context: context.newScope(),
            reuseIdProvider: reuseIdProvider)

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.dataSource = dataSource

        dataSource.collectionView = self.collectionView

        self.dataSource = dataSource

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "Use `init(model:modelBinder:viewBinder:layout:context:)`")
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        Log.fatal(message: "Use `init(model:modelBinder:viewBinder:layout:context:)`")
    }

    @available(*, unavailable, message: "Use `init(model:modelBinder:viewBinder:layout:context:)`")
    public required init?(coder aDecoder: NSCoder) {
        Log.fatal(message: "Use `init(model:modelBinder:viewBinder:layout:context:)`")
    }

    deinit {
        collectionView.delegate = nil
        collectionView.dataSource = nil

        unregisterForModelEvents()
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
    public var layout: UICollectionViewLayout {
        get {
            return collectionView.collectionViewLayout
        }
        set {
            collectionView.collectionViewLayout = layout
        }
    }

    /// Configures the background color of the collection view, as well as the background color of all host cells.
    open var backgroundColor = UIColor.white {
        didSet {
            dataSource.collectionViewBackgroundColor = backgroundColor
        }
    }

    /// Read-only access to the hosted `UICollectionView`.
    public let collectionView: UICollectionView

    // MARK: Public Intended for subclass override

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

    /// Adds a UIActivityIndicatorView to the center of the
    /// collectionView, and animates it.
    /// This method is called after the modelCollection state transitions 
    /// to .loading
    /// 
    /// Subclasses can override this together with `hideSpinner()`
    /// to provide custom .loading behavior.
    open func showSpinner() {
        guard self.spinner == nil else { return }

        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.spinner = spinner

        collectionView.addSubview(spinner)
        spinner.center = CGPoint(x: view.center.x, y: view.center.y * 0.66)
        spinner.startAnimating()
    }

    /// If a UIActivityIndicatorView was previously added by a call to
    /// `showSpinner()` This method will stop its animation and
    /// and remove it from its superview (the collectionView).
    ///
    /// This method is called before the modelCollection state 
    /// transitions to any state != .loading
    ///
    /// Subclasses can override this together with `showSpinner()`
    /// to provide custom .loading behavior.
    open func hideSpinner() {
        spinner?.removeFromSuperview()
        spinner?.stopAnimating()
        spinner = nil
    }

    // MARK: UIViewController

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = backgroundColor

        // Configure the collection view.
        collectionView.alwaysBounceVertical = true
        collectionView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        collectionView.backgroundColor = backgroundColor
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.frame = view.bounds
        collectionView.scrollsToTop = false
        collectionView.showsVerticalScrollIndicator = true

        view.addSubview(collectionView)

        dataSource.willRebindViewModel = { [weak self] viewModel in
            self?.willDisplayViewModel(viewModel)
        }

        // Register after the view loads so events don't trigger UX beforehand.
        registerForModelEvents()
    }

    open override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        dataSource.clearCachedItemSizes()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.scrollsToTop = true
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        collectionView.scrollsToTop = false
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        spinner?.center = CGPoint(x: view.center.x, y: view.center.y * 0.66)
    }

    // MARK: UICollectionViewDelegate

    open func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let viewModel = dataSource.viewModelAtIndexPath(indexPath) else { return }
        willDisplayViewModel(viewModel)
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let vm = dataSource.viewModelAtIndexPath(indexPath) else { return }
        if vm.canHandleUserEvent(.select) {
            vm.handleUserEvent(.select)
        }
    }

    // MARK: Private

    private var collectionObserver: Subscription?

    private func registerForModelEvents() {
        assertWithLog(collectionObserver == nil, message: "Expected to start with a nil token")

        collectionObserver = collection.observeValues { [weak self] event in
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
                hideSpinner()
            }

            switch state {
            case .notLoaded:
                break
            case .loading(let models):
                if models == nil || state.isEmpty {
                    showSpinner()
                }
            case .loaded:
                updateEmptyContentViewVisibility()
            case .error(_):
                updateEmptyContentViewVisibility()
            }
        }
    }

    /// Spinner to show when in the `Loading` state.
    private var spinner: UIActivityIndicatorView?

    /// View which is displayed when there is no content (either due to error or lack of loaded data).
    private var emptyContentView: UIView?

    private func showEmptyContentView() {
        guard self.emptyContentView == nil else { return }

        let display: EmptyCollectionDisplay
        if case .error(let error) = collection.state {
            display = displayForErrorState(error)
        } else {
            display = displayForNoContentState()
        }

        if let emptyContentView = emptyContentViewForDisplay(display) {
            self.emptyContentView = emptyContentView

            emptyContentView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyContentView)
            emptyContentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            emptyContentView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }

    private func hideEmptyContentView() {
        emptyContentView?.removeFromSuperview()
        emptyContentView = nil
    }

    private func updateEmptyContentViewVisibility() {
        switch collection.state {
        case .error(_), .loaded:
            if collection.state.isEmpty {
                showEmptyContentView()
            } else {
                hideEmptyContentView()
            }
        case .notLoaded, .loading:
            hideEmptyContentView()
        }
    }

    private func emptyContentViewForDisplay(_ display: EmptyCollectionDisplay) -> UIView? {
        switch display {
        case .none:
            return nil
        case .text(let string, let font, let color):
            let label = UILabel()
            label.backgroundColor = collectionView.backgroundColor
            label.font = font
            label.text = string
            label.textColor = color
            return label
        case .view(let view):
            return view
        }

    }
}
