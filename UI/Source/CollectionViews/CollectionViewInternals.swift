import Foundation
import Pilot

/// `Model` representing an empty section "item" - typically for supplementary view binding for empty sections.
internal struct CollectionZeroItemModel: Model {

    internal init(indexPath: IndexPath) {
        self.indexPath = indexPath
        self.modelId = "\(indexPath.modelSection)-\(indexPath.modelItem)-zero"
    }

    // MARK: Internal

    let indexPath: IndexPath

    // MARK: Model

    let modelId: ModelId
    let modelVersion = ModelVersion.unit
}

/// `ViewModel` representing an empty section "item" - typically for supplementary view binding for empty sections.
internal struct CollectionZeroItemViewModel: ViewModel {

    internal init(indexPath: IndexPath) {
        self.indexPath = indexPath
    }

    // MARK: Internal

    let indexPath: IndexPath

    // MARK: ViewModel

    @available(*, unavailable, message: "Unsupported initializer")
    init(model: Model, context: Context) {
        fatalError("Unsupported initializer")
    }

    let context = Context()
}
