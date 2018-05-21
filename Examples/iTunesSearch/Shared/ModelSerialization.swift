import Foundation
import Pilot

public protocol Media: Model {
    //init?(json: [String: Any])
}

extension Song: Media {
    public var release: Date {
        return serviceDateFormatter.date(from: releaseDate) ?? NSDate.distantPast
    }
}

extension TelevisionEpisode: Media {}
extension Podcast: Media {}

// MARK: Date Helpers

private let serviceDateFormatter: DateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return dateFormatter
}()
