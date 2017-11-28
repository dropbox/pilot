import Foundation

/// An optional protocol that types may adopt in order to provide a `ViewModel` directly. This is the default method
/// `ViewModelBindingProvider` uses to instantiate a `ViewModel`.
public protocol ViewModelConvertible {

    /// Return a `ViewModel` representing the target type.
    func viewModelWithContext(_ context: Context) -> ViewModel
}

/// Core binding provider protocol to generate `ViewModel` instances from `Model` instances.
public protocol ViewModelBindingProvider {

    /// Returns a `ViewModel` for the given `Model` and context.
    func viewModel(for model: Model, context: Context) -> ViewModel

    /// Returns the `SelectionViewModel` for given collection of models and a context. The default implementation
    /// returns selection view model that works for a single model.
    func selectionViewModel(for models: [Model], context: Context) -> SelectionViewModel?
}

extension ViewModelBindingProvider {
    public func selectionViewModel(for models: [Model], context: Context) -> SelectionViewModel? {
        if let firstModel = models.first, models.count == 1 {
            let firstViewModel = viewModel(for: firstModel, context: context)
            return ViewModelSelectionShim(viewModels: [firstViewModel], context: context)
        }
        return nil
    }
}

/// A `ViewModelBindingProvider` which provides default behavior to check the `Model` for conformance to
/// `ViewModelConvertible`.
public struct DefaultViewModelBindingProvider: ViewModelBindingProvider {

    public init() {}

    // MARK: ViewModelBindingProvider

    public func viewModel(for model: Model, context: Context) -> ViewModel {
        guard let convertible = model as? ViewModelConvertible else {
            // Programmer error to fail to provide a binding.
            // - TODO:(wkiefer) Avoid `fatalError` for programmer binding errors - return default empty views & assert.
            fatalError(
                "Default ViewModel binding requires model to conform to `ViewModelConvertible`: \(type(of: model))")
        }
        return convertible.viewModelWithContext(context)
    }
}

/// A `ViewModelBindingProvider` that delegates to a closure to provide the appropriate `ViewModel` for the
/// supplied `Model` and `Context`. It will fallback to the `DefaultViewModelBindingProvider` implementation
/// if no `ViewModel` is returned.
public struct BlockViewModelBindingProvider: ViewModelBindingProvider {
    public init(binder: @escaping (Model, Context) -> ViewModel?) {
        self.binder = binder
    }

    public func viewModel(for model: Model, context: Context) -> ViewModel {
        return self.binder(model, context) ?? DefaultViewModelBindingProvider().viewModel(for: model, context: context)
    }

    private let binder: (Model, Context) -> ViewModel?
}

/// Simple shim that forwards methods from `SelectionViewModel` to a single `ViewModel`.
fileprivate struct ViewModelSelectionShim: SelectionViewModel {
    init(viewModels: [ViewModel], context: Context) {
        guard let vm = viewModels.first else { fatalError("Shim constructed with empty view model collection") }
        self.context = context
        self.viewModel = vm
    }

    var context: Context
    var viewModel: ViewModel

    // MARK: ViewModelType

    func canHandleUserEvent(_ event: ViewModelUserEvent) -> Bool {
        return viewModel.canHandleUserEvent(event)
    }

    func handleUserEvent(_ event: ViewModelUserEvent) {
        return viewModel.handleUserEvent(event)
    }

    func secondaryActions(for event: ViewModelUserEvent) -> [SecondaryAction] {
        return viewModel.secondaryActions(for: event)
    }
}
