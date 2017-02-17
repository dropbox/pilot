/// AsyncModelCollection provides a simple interface for firing a single provider closure that can asynchronously return
/// an error or sectioned models.
public final class AsyncModelCollection: SimpleModelCollection {

    public enum Result {
        case success([[Model]])
        case error(Error)
    }
    public typealias Callback = (Result) -> Void
    public typealias Provider = (@escaping Callback) -> Void

    /// Init AsyncModelCollection with closure to provide sectioned models.
    /// Note: The callback must be called on the main thread!
    public init(modelProvider: Provider) {
        super.init()
        onNext(.loading(nil))
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
}
