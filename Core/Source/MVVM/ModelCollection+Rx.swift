#if canImport(RxSwift)
import RxSwift

extension ModelCollection {

    func asObservable() -> Observable<ModelCollectionState> {
        return Observable
            .create { (observer) in
                let sub = self.observeValues {
                    switch $0 {
                    case .didChangeState(let state): observer.onNext(state)
                    }
                }
                return Disposables.create {
                    sub.unsubscribe()
                }
            }
            .startWith(state)
    }
    
    func modelsObservable() -> Observable<[Model]> {
        return Observable
            .create { (observer) in
                let sub = self.observeValues {
                    switch $0 {
                    case .didChangeState(let state): observer.onNext(state.models)
                    }
                }
                return Disposables.create {
                    sub.unsubscribe()
                }
            }
            .startWith(models)
    }
}

#endif
