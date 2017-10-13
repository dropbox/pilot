import AppKit
import Pilot

extension NSMenu {

    /// Returns a `NSMenu` configured from the given `SecondaryAction` array. The given action will be invoked for
    /// each menu item selection. The receiver can call `NSMenuItem.representedAction` to get the action represented
    /// by the menu item in the implementation of the provided selector.
    public static func fromSecondaryActions(
        _ actions: [SecondaryAction],
        action: Selector,
        target: AnyObject? = nil
    ) -> NSMenu {
        let menu = NSMenu()

        // Enabling is set explicitly per-item below.
        menu.autoenablesItems = false

        actions.forEach { secondaryAction in
            switch secondaryAction {
            case .action(let info):
                let menuItem = NSMenuItem(title: info.title, action: action, keyEquivalent: "")
                menuItem.isEnabled = info.enabled
                menuItem.state = info.state.toNSState()
                menuItem.representedObject = MenuItemActionWrapper(info.action)
                if let imageName =  info.imageName {
                    menuItem.image = NSImage(named: imageName)
                }
                menuItem.target = target
                menu.addItem(menuItem)

            case .info(let string):
                let menuItem = NSMenuItem(title: string, action: action, keyEquivalent: "")
                menuItem.isEnabled = false
                menuItem.state = NSOffState
                menuItem.target = target
                menu.addItem(menuItem)

            case .separator:
                menu.addItem(NSMenuItem.separator())

            case .subactions(let title, let subactions):
                let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                menu.addItem(menuItem)
                let submenu = NSMenu.fromSecondaryActions(subactions, action: action, target: target)
                menu.setSubmenu(submenu, for: menuItem)
            }
        }
        return menu
    }
}

extension NSMenuItem {

    /// Returns the `Action` represented by a menu item created via `NSMenu.fromSecondaryActions(action:)` so that
    /// it may be sent.
    public var representedAction: Action? {
        if let wrapper = representedObject as? MenuItemActionWrapper {
            return wrapper.wrappedAction
        }
        return nil
    }
}

extension SecondaryActionInfo.State {
    fileprivate func toNSState() -> Int {
        switch self {
        case .on:
            return NSOnState
        case .mixed:
            return NSMixedState
        case .off:
            return NSOffState
        }
    }
}

/// Helper class to wrap value-type `Action`s.
fileprivate final class MenuItemActionWrapper: NSObject {

    fileprivate convenience init(_ action: Action) {
        self.init()
        wrappedAction = action
    }
    fileprivate var wrappedAction: Action?
}

