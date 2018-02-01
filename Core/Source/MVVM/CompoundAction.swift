
/// Action implementation which fires all its child actions serially in send(from:).
///
/// Note: returns .handled as the ActionResult if any of the child actions are handled.
public struct CompoundAction: Action {

    public init(_ actions: [Action]) {
        self.actions = actions
    }

    public let actions: [Action]
}

extension Action {

    /// Chains two actions together creating a compound action, flattening if either or both are compound actions.
    public func with(_ other: Action) -> CompoundAction {
        let lhs = (self as? CompoundAction)?.actions ?? [self]
        let rhs = (other as? CompoundAction)?.actions ?? [other]
        return CompoundAction(lhs + rhs)
    }
}
