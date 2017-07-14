import Pilot

public struct TopicViewModel: ViewModel {
    
    // MARK: Init
    
    public init(topic: Topic, context: Context) {
        self.topic = topic
        self.context = context
    }
    
    // MARK: Public
    
    public var title: String {
        switch topic {
        case .modelCollections:
            return "ModelCollection"
        }
    }
    
    // MARK: ViewModel
    
    public init(model: Model, context: Context) {
        self.init(topic: model.typedModel(), context: context)
    }
    
    public let context: Context
    
    public func handleUserEvent(_ event: ViewModelUserEvent) {
        if context.shouldNavigate(for: event) {
            NavigateAction(destination: .topic(topic)).send(from: context)
        }
    }
    
    // MARK: Private
    
    private let topic: Topic
}

extension Topic: ViewModelConvertible {
    public func viewModelWithContext(_ context: Context) -> ViewModel {
        return TopicViewModel(topic: self, context: context)
    }
}
