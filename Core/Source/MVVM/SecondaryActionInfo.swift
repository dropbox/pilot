import Foundation

/// Wraps an `Action` with additional data to be rendered in a "secondary" context like context menus or long-press
/// menus.
public struct SecondaryActionInfo {
    public struct Metadata {
        public let title: String
        public let state: State
        public let enabled: Bool
        public let imageName: String?
        public let keyEquivalent: String

        /// State of the secondary action. Note that this differs from enabled, but instead represents whether the
        /// action is "checked" in a list.
        public enum State: ExpressibleByBooleanLiteral {
            case on
            case off
            case mixed

            public init(booleanLiteral value: BooleanLiteralType) {
                if value {
                    self = .on
                } else {
                    self = .off
                }
            }
        }

        // Always provide a default value, so that it is easy to create partial Metadata to overlay on top on an
        // existing item. For example, an AppActionResponder may want to pass up Metadata(state: .on) to add
        // a checkmark to an item, without knowing the exact name of the action.
        public init(
            title: String = "",
            state: Metadata.State = .off,
            enabled: Bool = true,
            imageName: String? = nil,
            keyEquivalent: String = ""
            ) {
            self.title = title
            self.state = state
            self.enabled = enabled
            self.imageName = imageName
            self.keyEquivalent = keyEquivalent
        }

        // Enforce some common conventions (for example, state is off, no keyEquivalent).
        public static func forNestedActions(
            title: String,
            enabled: Bool = true,
            imageName: String? = nil
            ) -> Metadata {
            return Metadata(title: title, state: .off, enabled: enabled, imageName: imageName)
        }
    }

    public init(metadata: Metadata, action: Action) {
        self.metadata = metadata
        self.action = action
    }

    public let metadata: Metadata
    public let action: Action
}

/// Describes a group of nested SecondaryActions.
public struct NestedActionsInfo {
    public init(metadata: SecondaryActionInfo.Metadata, actions: [SecondaryAction]) {
        self.metadata = metadata
        self.actions = actions
    }

    public let metadata: SecondaryActionInfo.Metadata
    public let actions: [SecondaryAction]
}

/// Represents a secondary action to be displayed in a list to the user (typically from right-click or long-press).
public enum SecondaryAction {
    case action(SecondaryActionInfo)
    case info(String)
    case separator
    case nested(NestedActionsInfo)
}
