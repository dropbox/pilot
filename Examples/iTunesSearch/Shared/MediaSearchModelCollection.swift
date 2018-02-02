import Foundation
import Pilot

public final class MediaSearchModelCollection: SimpleModelCollection {

    init() {
        super.init(collectionId: "MediaSearchModelCollection")
        onNext(.loaded([]))
    }

    // MARK: Public

    public enum MediaSearchError: Error {
        case service(Error)
        case unknown
    }

    public func updateQuery(_ query: String) {
        guard query != previousQuery else { return }
        onNext(.loading(state.sections))
        previousQuery = query
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
            guard query == self?.previousQuery else { return }
        self?.service.search(term: query, limit: 100) { [weak self] (media, error) in
                DispatchQueue.main.async {
                    guard let strongSelf = self, strongSelf.previousQuery == query else { return }
                    if let media = media {
                        strongSelf.onNext(.loaded([media]))
                    } else {
                        let error: MediaSearchError = error.flatMap({ .service($0) }) ?? .unknown
                        strongSelf.onNext(.error(error))
                    }
                }
            }
        }
    }

    // MARK: Private

    private let service = SearchService()
    private var previousQuery: String?
}
