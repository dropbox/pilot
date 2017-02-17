import Foundation

/// A concrete implementation of `ViewBindingProvider` which handles binding `StaticViewModel` types to a single
/// `View`. Typically used alongside `StaticModelCollection` to create a full MVVM stack out of
/// simple or static data.
///
/// The `View.Type` passed at initialization is typically an application-specific view instance which can render
/// the `StaticData` generic type of `StaticModel`/`StaticViewModel`.
///
/// Example usage below (this uses PilotUI for the actual view rendering and a pretend `MyStringView` as an application
/// custom view.
///
/// ```swift
/// let data: [[Model]] = [[
///     "Item 1", "Item 2", "Item 3"
///  ]]
///
/// let model = StaticModelCollection(initialData: data)
/// let binder = StaticViewBindingProvider(type: MyStringView.self)
/// let layout = UICollectionViewFlowLayout()
///
/// let vc = CollectionViewController(
///     model: model,
///     modelBinder: DefaultViewModelBindingProvider(),
///     viewBinder: binder,
///     layout: layout,
///     context: nil)
/// ```
public struct StaticViewBindingProvider<T>: ViewBindingProvider where T: View {

    // MARK: Init

    /// NOTE: Constructor only used to specify T.
    public init(type: T.Type) {
    }

    // MARK: ViewBindingProvider

    public func viewBinding(for viewModel: ViewModel, context: Context) -> ViewBinding {
        return ViewBinding(T.self)
    }

    public func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel,
        context: Context
    ) -> PreferredLayout {
        return T.preferredLayout(fitting: availableSize, for: viewModel)
    }
}
