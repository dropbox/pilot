import Foundation
import RxSwift

// Temporary until Xcode9.3 is baseline.
#if !swift(>=4.1)
extension Sequence {
    internal func compactMap<ElementOfResult>(
        _ transform: (Self.Element) throws -> ElementOfResult?
    ) rethrows -> [ElementOfResult] {
        return try flatMap(transform)
    }
}
#endif


public class SearchService {

    public enum ServiceError: Error {
        case service(description: String)
        case network(Error)
        case json(Error)
        case unknown
    }
    
    public func search(term: String, limit: Int) -> Single<[Media]?> {
        return Single.create(subscribe: { (sub) -> Disposable in
            self.search(term: term, limit: limit) { (media, error) in
                if let error = error {
                    sub(SingleEvent.error(error))
                }
                sub(SingleEvent.success(media ?? []))
            }
            return Disposables.create()
        })
    }

    public func search(
        term: String,
        limit: Int,
        completion: @escaping ([Media]?, ServiceError?) -> Void
    ) {

        let baseURL = URL(string: "https://itunes.apple.com/search")!
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let requestURL = components?.url else {
            completion(nil, .service(description: "Couldn't form URL"))
            return
        }
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            if let error = error {
                return completion(nil, ServiceError.network(error))
            }
            guard let data = data else {
                return completion(nil, ServiceError.service(description: "Empty response"))
            }
            do {
                let decoder = JSONDecoder()
                let serviceResponse = try decoder.decode(SearchServiceResponse.self, from: data)

                let media: [Media] = serviceResponse.results.compactMap { result in
                    switch result.model {
                    case .podcast(let podcast): return podcast
                    case .song(let song): return song
                    case .televisionEpisode(let episode): return episode
                    case .unknown:
                        return nil
                    }
                }

                return completion(media, nil)
            } catch let e {
                return completion(nil, .json(e))
            }
        }
        task.resume()
    }
}
