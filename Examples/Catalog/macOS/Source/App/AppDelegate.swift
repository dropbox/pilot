import Cocoa

@NSApplicationMain
public final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: NSApplicationDelegate

    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        rootWindowController = RootWindowController(context: nil)
        rootWindowController.window?.makeKeyAndOrderFront(nil)
    }
    
    // MARK: Private
    
    @IBOutlet
    private var rootWindowController: RootWindowController!
}

