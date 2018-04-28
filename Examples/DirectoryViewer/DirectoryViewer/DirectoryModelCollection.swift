import Pilot

public final class DirectoryModelCollection: NestedModelCollection, ProxyingCollectionEventObservable {
    public init(url: URL) {
        self.collectionId = "DMC-\(url.path)"
        self.fileURLs = DirectoryModelCollection.scanDirectory(url) ?? []
        let queue = DispatchQueue(label: "DispatchFileEventSource")
        let handle: Int32 = open(url.path, O_EVTONLY)
        guard handle != -1 else {
            let error = NSError(
                domain: "pilot.examples",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to create dispatch file event source for path"])
            self.state = .error(error)
            self.fileHandle = nil
            self.dispatchSource = nil
            return
        }

        self.state = .loaded(fileURLs.map(File.init(url:)))
        self.fileHandle = handle
        self.dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: handle,
            eventMask: [.all],
            queue: queue)

        self.dispatchSource?.setEventHandler { [weak self] in
            guard let updatedURLs = DirectoryModelCollection.scanDirectory(url) else {
                return
            }
            DispatchQueue.main.async {
                if let urls = self?.fileURLs, urls != updatedURLs  {
                    self?.fileURLs = updatedURLs
                } else if self?.fileURLs == nil {
                    self?.fileURLs = updatedURLs
                }
            }
        }
        self.dispatchSource?.resume()
    }

    deinit {
        self.dispatchSource?.setEventHandler(handler: nil)
        if let handle = fileHandle {
            close(handle)
        }
    }

    // MARK: CollectionEventObservable

    public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId
    public var state: ModelCollectionState {
        didSet { observers.notify(.didChangeState(state)) }
    }

    // MARK: NestedModelCollection

    public func canExpand(_ model: Model) -> Bool {
        let file: File = model.typedModel()
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: file.url.path, isDirectory: &isDir)
        return isDir.boolValue
    }

    public func childModelCollection(for model: Model) -> NestedModelCollection {
        guard canExpand(model) else {
            return EmptyModelCollection().asNested()
        }
        let file: File = model.typedModel()
        return DirectoryModelCollection(url: file.url)
    }

    // MARK: Private

    private let dispatchSource: DispatchSourceFileSystemObject?
    private let fileHandle: Int32?

    private static func scanDirectory(_ url: URL) -> [URL]? {
        return try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
    }

    private var fileURLs: [URL] {
        didSet {
            state = .loaded(fileURLs.map(File.init(url:)))
        }
    }
}
