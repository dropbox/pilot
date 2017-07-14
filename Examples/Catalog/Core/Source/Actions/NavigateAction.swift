import Pilot

public struct NavigateAction: Action {
    public enum Destination {
        case topic(Topic)
        case modelCollectionExample(ModelCollectionExample)
    }
    
    public init(destination: Destination) {
        self.destination = destination
    }
    
    public let destination: Destination
}
