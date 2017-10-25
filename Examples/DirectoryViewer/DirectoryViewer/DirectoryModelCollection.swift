import Pilot

public final class DirectoryModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    public init(url: URL) {
        self.collectionId = "DMC-\(url.path)"
        self.fileURLs = try! FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
        self.state = .loaded([fileURLs.map { File(url: $0) }])
    }

    // MARK: CollectionEventObservable

    public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId
    public var state: ModelCollectionState {
        didSet { observers.notify(.didChangeState(state)) }
    }

    // MARK: Private

    private var fileURLs: [URL] {
        didSet {
            state = .loaded([fileURLs.map({ File(url: $0) })])
        }
    }
}
