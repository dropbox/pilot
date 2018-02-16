import Pilot

public protocol ExampleViewModel: ViewModel {
    var exampleTitle: String { get }
}

extension ModelCollectionExampleViewModel: ExampleViewModel {
    public var exampleTitle: String {
        return title
    }
}
