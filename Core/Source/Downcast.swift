extension Model {

    /// Force downcasts model to a specific type, necessary due to limitations on generic protocols in swift.
    public func typedModel<M: Model>(file: StaticString = #file, line: UInt = #line) -> M {
        guard let result = self as? M else {
            preconditionFailure("Unexpected encountered Model of type \(type(of: self))", file: file, line: line)
        }
        return result
    }
}

extension ViewModel {

    /// Force downcasts ViewModel to a specific type, necessary due to limitations on generic protocols in swift.
    public func typedViewModel<VM: ViewModel>(file: StaticString = #file, line: UInt = #line) -> VM {
        guard let result = self as? VM else {
            preconditionFailure("Unexpected encountered ViewModel of type \(type(of: self))", file: file, line: line)
        }
        return result
    }
}
