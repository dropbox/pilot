extension Model {

    /// Force downcasts Model to a specific type, necessary due to limitations on generic protocols in swift.
    public func typedModel<M: Model>(file: StaticString = #file, line: UInt = #line) -> M {
        guard let result = self as? M else {
            preconditionFailure("Unexpectedly encountered Model of type \(type(of: self))", file: file, line: line)
        }
        return result
    }
}

extension ViewModel {

    /// Force downcasts ViewModel to a specific type, necessary due to limitations on generic protocols in swift.
    public func typedViewModel<VM: ViewModel>(file: StaticString = #file, line: UInt = #line) -> VM {
        guard let result = self as? VM else {
            preconditionFailure("Unexpectedly encountered ViewModel of type \(type(of: self))", file: file, line: line)
        }
        return result
    }
}

extension Context {

    /// Force downcasts Context to a specific type, necessary due to limitations on generic protocols in swift.
    public func typedContext<C: Context>(file: StaticString = #file, line: UInt = #line) -> C {
        guard let result = self as? C else {
            preconditionFailure("Unexpectedly encountered Context of type \(type(of: self))", file: file, line: line)
        }
        return result
    }
}

