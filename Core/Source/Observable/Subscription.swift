import Foundation

/// Representation of an Observable subscription.
///
///
/// On unsubscribe() or on deinit unsubscribeAction will be called. It will only be called once regardless.
public final class Subscription {

    // MARK: Init / Deinit
    
    internal typealias UnsubscribeAction = () -> Void

    internal init(_ unsubscribeAction: @escaping UnsubscribeAction) {
        self.unsubscribeAction = unsubscribeAction
    }

    deinit {
        unsubscribe()
    }
    
    internal static let inert = Subscription({})
    
    // MARK: Public

    public func unsubscribe() {
        if OSAtomicCompareAndSwap32Barrier(0, 1, &isDisposed) {
            unsubscribeAction?()
            unsubscribeAction = nil
        }
    }
    
    // MARK: Private

    private var isDisposed: Int32 = 0
    private var unsubscribeAction: UnsubscribeAction?
}

#if canImport(RxSwift)
import RxSwift
#endif
