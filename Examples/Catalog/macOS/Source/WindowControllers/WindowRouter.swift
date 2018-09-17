import AppKit
import CatalogCore
import Pilot

public final class WindowRouter {
    
    // MARK: Init
    
    public init(window: NSWindow, rootSplitViewController: RootSplitViewController, context: CatalogContext) {
        self.context = context
        self.rootSplitViewController = rootSplitViewController
        
        configureInitialViewControllers()
        
        contextSubscription = context.receiveAll { [weak self] action in
            return self?.handle(action) ?? .notHandled
        }
    }
    
    // MARK: Private
    
    private let context: CatalogContext
    private var contextSubscription: Subscription?
    
    private let rootSplitViewController: RootSplitViewController

    private func handle(_ action: Action) -> ActionResult {
        switch action {
        case let x as NavigateAction:
            return handleNavigate(x)
        default:
            return .notHandled
        }
    }
    
    private func handleNavigate(_ action: NavigateAction) -> ActionResult {
        switch action {
        case .topic(let topic):
            show(topic)
        case .modelCollectionExample(let example):
            show(example)
        }
        return .handled
    }
    
    private func configureInitialViewControllers() {
        rootSplitViewController.sidebarViewController = TopicCollectionViewController.make(with: context)
    }
    
    private func show(_ topic: Topic) {
        let contentListViewController: NSViewController
        switch topic {
        case .modelCollections:
            contentListViewController = ModelCollectionExampleCollectionViewController.make(with: context)
        }
        rootSplitViewController.contentListViewController = contentListViewController
        rootSplitViewController.detailViewController = EmptyViewController(backgroundColor: .white)
    }
    
    private func show(_ modelCollectionExample: ModelCollectionExample) {
        // TODO:(wkiefer) Implement.
    }
}
