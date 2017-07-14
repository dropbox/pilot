import Pilot

public struct ModelCollectionExampleViewModel: ViewModel {
    
    // MARK: Init
    
    public init(example: ModelCollectionExample, context: Context) {
        self.example = example
        self.context = context
    }
    
    // MARK: Public
    
    public var title: String {
        switch example {
        case .filtered:
            return "Filtered"
        case .sorted:
            return "Sorted"
        }
    }
    
    // MARK: ViewModel
    
    public init(model: Model, context: Context) {
        self.init(example: model.typedModel(), context: context)
    }
    
    public let context: Context
    
    // MARK: Private
    
    private let example: ModelCollectionExample
}

extension ModelCollectionExample: ViewModelConvertible {
    public func viewModelWithContext(_ context: Context) -> ViewModel {
        return ModelCollectionExampleViewModel(example: self, context: context)
    }
}

