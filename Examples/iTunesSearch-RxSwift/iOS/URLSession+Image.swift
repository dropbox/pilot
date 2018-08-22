import Foundation
import UIKit

extension URLSession {

    public enum ImageLoadingError: Error {
        case unknown
    }

    public func imageTask(
        with url: URL,
        completionHandler: @escaping (UIImage?, Error?) -> Swift.Void
    ) -> URLSessionDataTask {
        return dataTask(with: url, completionHandler: { (data, _, error) in
            if let data = data {
                DispatchQueue.main.async {
                    completionHandler(UIImage(data: data), nil)
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(nil, error ?? ImageLoadingError.unknown)
                }
            }
        })
    }
}
