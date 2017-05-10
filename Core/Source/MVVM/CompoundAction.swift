
/// Action implementation which fires all its child actions serially in send(from:).
///
/// Note: returns .handled as the ActionResult if any of the child actions are handled.
public struct CompoundAction: Action {

    public init(childActions: [Action]) {
        self.childActions = childActions
    }

    public let childActions: [Action]
}

extension Action {

    /// Chains two actions together creating a compound action, flattening if either or both are compound actions.
    public func with(_ other: Action) -> CompoundAction {
        let lhs = (self as? CompoundAction)?.childActions ?? [self]
        let rhs = (other as? CompoundAction)?.childActions ?? [other]
        return CompoundAction(childActions: lhs + rhs)
    }
}
