import Foundation

public class SearchService {

    public enum ServiceError: Error {
        case service(description: String)
        case network(Error)
        case json(Error)
        case unknown
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
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                let map = json as? [String: Any]
                let results = (map?["results"] as? [Any]) ?? []
                let media = results.flatMap { (media: Any) -> Media? in
                    if
                        let mediaJSON = media as? [String: Any],
                        let mediaKind = mediaJSON["kind"] as? String,
                        let mediaType = TrackKind(rawValue: mediaKind)?.modelType
                    {
                        return mediaType.init(json: mediaJSON)
                    }
                    return nil
                }
                return completion(media, nil)
            } catch let e {
                completion(nil, .json(e))
                return
            }
        }
        task.resume()
    }
}
