import AppKit
import CatalogCore
import Pilot

public final class WindowRouter {
    
    // MARK: Init
    
    public init(window: NSWindow, rootSplitViewController: RootSplitViewController, context: CatalogContext) {
        self.context = context
        self.rootSplitViewController = rootSplitViewController
        
        configureInitialViewControllers()
    }
    
    // MARK: Private
    
    private let context: CatalogContext
    private let rootSplitViewController: RootSplitViewController
    
    private func configureInitialViewControllers() {
        rootSplitViewController.sidebarViewController = TopicCollectionViewController.make(with: context)
    }
}
