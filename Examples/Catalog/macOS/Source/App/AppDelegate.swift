import Cocoa
import CatalogCore

@NSApplicationMain
public final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: NSApplicationDelegate

    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        rootWindowController = WindowController(context: rootContext)
        rootWindowController.window?.makeKeyAndOrderFront(nil)
    }
    
    // MARK: Private
    
    /// Each application using Pilot has an application-level root `Context`. Typically each window creates a new
    /// scope for handling actions within that window. In catalog, that happens in the `WindowController` initializer.
    private let rootContext = CatalogContext()
    
    /// For simplicity, Catalog has a single window controller.
    @IBOutlet
    private var rootWindowController: WindowController!
}

