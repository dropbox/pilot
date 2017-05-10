
/// Action implementation which fires all its child actions serially in send(from:).
///
/// Note: returns .handled as the ActionResult if any of the child actions return .handled in send(from:).
public struct CompoundAction: Action {

    public init(childActions: [Action]) {
        self.childActions = childActions
    }

    public let childActions: [Action]

    @discardableResult
    public func send(from sender: ActionSender) -> ActionResult {
        var result: ActionResult = .notHandled
        for action in childActions {
            if case .handled = action.send(from: sender) {
                result = .handled
            }
        }
        return result
    }
}

extension Action {

    public func with(_ other: Action) -> CompoundAction {
        return CompoundAction(childActions: [self, other])
    }
}

