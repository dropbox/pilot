import Foundation
import Pilot

/// Action which presents an alert with title, description, and buttons that can optionally fire their own sub-actions.
public struct AlertAction: Action {

    public init(style: AlertStyle = .sheet, title: String?, message: String?, buttons: [AlertButton]) {
        self.style = style
        self.title = title
        self.message = message
        self.buttons = buttons
    }

    public let style: AlertStyle
    public let title: String?
    public let message: String?
    public typealias AlertButton = (title: String, type: ButtonType, action: Action?)
    public let buttons: [AlertButton]

    /// Determines whether to display a sheet on the current window or as a floating dialog.
    public enum AlertStyle {
        case sheet, dialog
    }

    public enum ButtonType {
        case normal, cancel, destructive
    }
}
