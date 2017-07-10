import AppKit
import CatalogCore
import Pilot

public final class WindowController: NSWindowController, NSWindowDelegate {
    
    // MARK: Init
    
    public init(context: CatalogContext) {
        // Set up the root split view controller.
        let rootSplitViewController = RootSplitViewController()
        rootSplitViewController.preferredContentSize = NSSize(width: 600, height: 400)
        
        // Create the window.
        let window = NSWindow(contentViewController: rootSplitViewController)
        window.styleMask =
            [.closable, .miniaturizable, .resizable, .fullSizeContentView, .unifiedTitleAndToolbar, .titled]
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 600, height: 400)
        
        // Create a child ocntext scoped to the window itself.
        let windowScopedContext = context.newScope()
        self.context = windowScopedContext
        
        // Create the window router to handle navigation and view controller setup.
        self.router = WindowRouter(
            window: window,
            rootSplitViewController: rootSplitViewController,
            context: windowScopedContext)
        
        super.init(window: window)
        
        // Enable a layer-backed window.
        window.contentView?.wantsLayer = true
        
        // Not called when using `init(window:)` - call for consistency in setup code.
        windowDidLoad()
        
        window.delegate = self
        window.windowController = self
    }
    
    public override init(window: NSWindow?) {
        fatalError()
    }
    
    public required init?(coder: NSCoder) {
        fatalError()
    }
    
    deinit {
        window?.delegate = nil
        window?.windowController = nil
    }
    
    public let router: WindowRouter
    
    // MARK: NSWindowController
    
    public override var windowNibName: NSNib.Name? {
        return nil
    }
    
    public override func windowDidLoad() {
        super.windowDidLoad()
        
        // Set up a toolbar.
        let emptyToolbar = NSToolbar(identifier: NSToolbar.Identifier(rawValue: "EmptyToolbar"))
        emptyToolbar.displayMode = .iconOnly
        window?.toolbar = emptyToolbar
    }
    
    // MARK: Private
    
    private let context: CatalogContext
}
