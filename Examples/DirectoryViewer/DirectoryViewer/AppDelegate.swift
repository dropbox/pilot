import Cocoa
import Pilot
import PilotUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: NSApplicationDelegate

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.minSize = CGSize(width: 480, height: 360)

        /* TODO:(danielh) add toggle for outline view / colleciton view
        window.contentViewController = DirectoryOutlineViewController(
            url: FileManager.default.homeDirectoryForCurrentUser,
            context: rootContext)
        */
        window.contentViewController = DirectoryCollectionViewController(
            url: FileManager.default.homeDirectoryForCurrentUser,
            context: rootContext)

        openFilesObserver = rootContext.receive { [weak self] (open: OpenFilesAction) -> ActionResult in
            for url in open.urls {
                self?.openFile(url)
            }
            return .handled
        }
    }

    // MARK: Public

    @IBOutlet public weak var window: NSWindow!

    // MARK: Private

    private let rootContext = Context()
    private var openFilesObserver: Observer?
    private var subwindows = [NSWindowController]()

    @objc
    private func newDocument(_ sender: Any) {
        openWindow(url: FileManager.default.homeDirectoryForCurrentUser)
    }

    private func openFile(_ url: URL) {
        var isDirectory: ObjCBool = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return }
        if isDirectory.boolValue {
            openWindow(url: url)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    private func openWindow(url: URL) {
        let origin: CGPoint
        if let key = NSApp?.keyWindow, let screen = key.screen {
            let keyWindowOrigin = key.frame.origin
            let maxX = screen.frame.width
            origin = CGPoint(x: min(maxX, keyWindowOrigin.x + 25), y: max(0, keyWindowOrigin.y - 50))
        } else {
            origin = .zero
        }
        let size = NSApp?.keyWindow?.frame.size ?? CGSize(width: 480, height: 360)
        let rect = CGRect(origin: origin, size: size)
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.minSize = size
        let content = DirectoryCollectionViewController(
            url: url,
            context: rootContext)
        window.contentViewController = content
        let controller = NSWindowController(window: window)
        subwindows.append(controller) // fixme: leak
        window.makeKeyAndOrderFront(nil)
    }
}
