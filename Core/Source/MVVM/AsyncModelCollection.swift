/// AsyncModelCollection provides a simple interface for firing a single provider closure that can asynchronously return
/// an error or sectioned models.
public final class AsyncModelCollection: SimpleModelCollection {

    public enum Result {
        case success([Model])
        case error(Error)
    }
    public typealias Callback = (Result) -> Void
    public typealias Provider = (@escaping Callback) -> Void

    /// Init AsyncModelCollection with closure to provide sectioned models. The closure will be retained and called when
    /// `fetch()` is called. Note: The callback must be called on the main thread!
    public init(
        collectionId: ModelCollectionId = "asyncmodelcollection-" + Token.makeUnique().stringValue,
        modelProvider: @escaping Provider
    ) {
        self.modelProvider = modelProvider
        super.init(collectionId: collectionId)
    }

    /// Sets state to loading and then calls the `modelProvider`, will stay loaded until the closure returns with an
    /// error or models. Note it's caller's responsibility to ensure this isn't called multiple times before the closure
    /// returns.
    public func fetch() {
        switch state {
        case .notLoaded:
            onNext(.loading(nil))
        default:
            onNext(.loading(models))
        }

        modelProvider { [weak self] (result) in
            precondition(Thread.isMainThread)
            switch result {
            case .error(let error):
                self?.onNext(.error(error))
            case .success(let model):
                self?.onNext(.loaded(model))
            }
        }
    }

    private let modelProvider: Provider
}
