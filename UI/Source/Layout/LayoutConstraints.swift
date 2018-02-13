
internal struct ConstraintEdges: OptionSet {
    internal let rawValue: Int
    internal init(rawValue: Int) {
        self.rawValue = rawValue
    }

    internal static let top = ConstraintEdges(rawValue:1)
    internal static let leading = ConstraintEdges(rawValue:2)
    internal static let bottom = ConstraintEdges(rawValue:4)
    internal static let trailing = ConstraintEdges(rawValue:8)
    internal static let all: ConstraintEdges = [.top, leading, bottom, trailing]
}

#if os(iOS)
private let zero = UIEdgeInsets.zero
#elseif os(OSX)
private let zero = NSEdgeInsetsZero
#endif

extension PlatformView {

    @discardableResult
    internal func constrain(
        edges: ConstraintEdges,
        equalToView view: PlatformView,
        insets: PlatformEdgeInsets = zero
    ) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        if edges.contains(.top) {
            constraints.append(topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top))
        }
        if edges.contains(.leading) {
            constraints.append(leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left))
        }
        if edges.contains(.bottom) {
            constraints.append(bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom))
        }
        if edges.contains(.trailing) {
            constraints.append(trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right))
        }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    @discardableResult
    internal func constrain(
        edgesEqualToView view: PlatformView,
        insets: PlatformEdgeInsets = zero
    ) -> [NSLayoutConstraint] {
        return self.constrain(edges: .all, equalToView: view, insets: insets)
    }
}

extension NSLayoutConstraint {

    @discardableResult
    internal func with(priority p: PlatformLayoutPriority) -> NSLayoutConstraint {
        #if os(OSX)
        priority = NSLayoutConstraint.Priority(p)
        #else
        priority = UILayoutPriority(rawValue: p)
        #endif
        return self
    }
}
