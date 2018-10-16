import Foundation
import RxSwift

/// Simple implementation of an generic either type for a result that can either be a success <S> or failure <F>.
public enum Result<S, F> {
    case success(S)
    case failure(F)

    public var value: S? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    public var error: F? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

extension ObservableType {
    /// Utility function tat takes Observable<T> and turns it into a Observable<Result<T, Error>>
    /// passing converting an error in the Observable to a Result.failure but not terminating stream.
    public func mappedToResult() -> RxSwift.Observable<Result<Self.E, Error>> {
        return materialize()
            .map { (input: Event<E>) -> Event<Result<E, Error>> in
                switch input {
                case .completed: return .completed
                case .next(let e): return .next(Result.success(e))
                case .error(let e): return .next(Result.failure(e))
                }
            }
            .dematerialize()
    }
}
