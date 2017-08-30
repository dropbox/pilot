import Foundation


/// Concrete `Model` implementation which is generic on any data. Commonly used along with `StaticViewModel` and
/// `SimpleModelCollectionConfiguration` for creating full MVVM stacks using simple data.
///  e.g. `let item = StaticModel(modelId: "1", data: "Some string")`
public struct StaticModel<StaticData>: Model, ViewModelConvertible {

    // MARK: Init

    public init(modelId: ModelId, data: StaticData) {
        self.modelId = modelId
        self.data = data
    }

    // MARK: Public

    public let data: StaticData

    // MARK: Model

    public let modelId: ModelId

    /// NOTE: updating a collection with a StaticModel of the same modelId but different data will not update the view.
    /// Specify a different ID if the data is different.
    public let modelVersion = ModelVersion.unit

    // MARK: ViewModelConvertible

    public func viewModelWithContext(_ context: Context) -> ViewModel {
        return StaticViewModel<StaticData>(model: self, context: context)
    }
}

/// Concrete `ViewModel` implementation which binds to a `StaticModel<StaticData>` type. Commonly used along with
/// `StaticModel` and `SimpleModelCollectionConfiguration` for creating full MVVM stacks using simple data.
public struct StaticViewModel<StaticData>: ViewModel {

    // MARK: Public

    public var data: StaticData {
        return model.data
    }

    // MARK: ViewModel

    public init(model: Model, context: Context) {
        guard let staticModel = model as? StaticModel<StaticData> else {
            Log.fatal(message: "StaticModel StaticData type does not match StaticViewModel StaticData type")
        }
        self.model = staticModel
        self.context = context
    }

    public let context: Context

    // MARK: Private

    private let model: StaticModel<StaticData>
}
