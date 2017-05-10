import AppKit
import Pilot

extension NSMenu {

    /// Returns a `NSMenu` configured from the given `SecondaryAction` array. The given action will be invoked for
    /// each menu item selection. The receiver can call `NSMenuItem.representedAction` to get the action represented
    /// by the menu item in the implementation of the provided selector.
    public static func fromSecondaryActions(_ actions: [SecondaryAction], action: Selector) -> NSMenu {
        let menu = NSMenu()

        // Enabling is set explicitly per-item below.
        menu.autoenablesItems = false

        actions.forEach { secondaryAction in
            switch secondaryAction {
            case .action(let info):
                // TODO:(wkiefer) Image support.
                let menuItem = NSMenuItem(title: info.title, action: action, keyEquivalent: "")
                menuItem.isEnabled = info.enabled
                menuItem.state = info.state.toNSState()
                menuItem.representedObject = MenuItemActionWrapper(info.action, event: info.event)
                menu.addItem(menuItem)

            case .info(let string):
                let menuItem = NSMenuItem(title: string, action: action, keyEquivalent: "")
                menuItem.isEnabled = false
                menuItem.state = NSOffState
                menu.addItem(menuItem)

            case .separator:
                menu.addItem(NSMenuItem.separator())
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

    /// TODO:(danielh) docs
    public var representedEvent: AnalyticsEvent? {
        if let wrapper = representedObject as? MenuItemActionWrapper {
            return wrapper.wrappedEvent
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

    fileprivate convenience init(_ action: Action, event: AnalyticsEvent?) {
        self.init()
        wrappedAction = action
        wrappedEvent = event
    }
    fileprivate var wrappedAction: Action?
    fileprivate var wrappedEvent: AnalyticsEvent?
}

