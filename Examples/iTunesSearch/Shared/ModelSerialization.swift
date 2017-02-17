import Foundation
import Pilot

public protocol Media: Model {
    init?(json: [String: Any])
}

extension Song: Media {
    public init?(json: [String: Any]) {
        guard
            let artistId = json["artistId"] as? Int,
            let collectionId = json["collectionId"] as? Int,
            let trackId = json["trackId"] as? Int,
            let artistName = json["artistName"] as? String,
            let collectionName = json["collectionName"] as? String,
            let trackName = json["trackName"] as? String,
            let artistURLString = json["artistViewUrl"] as? String,
            let artistView = URL(string: artistURLString),
            let previewURLString = json["previewUrl"] as? String,
            let preview = URL(string: previewURLString),
            let collectionViewUrlString = json["collectionViewUrl"] as? String,
            let collectionView = URL(string: collectionViewUrlString),
            let trackViewURLString = json["trackViewUrl"] as? String,
            let trackView = URL(string: trackViewURLString),
            let collectionPrice = json["collectionPrice"] as? Float,
            let trackPrice = json["trackPrice"] as? Float,
            let releaseString = json["releaseDate"] as? String,
            let release = serviceDateFormatter.date(from: releaseString),
            let durationMilliseconds = json["trackTimeMillis"] as? Int
        else {
                return nil
        }

        self.artistId = artistId
        self.collectionId = collectionId
        self.trackId = trackId
        self.artistName = artistName
        self.collectionName = collectionName
        self.trackName = trackName
        self.artistView = artistView
        self.preview = preview
        self.trackView = trackView
        self.collectionView = collectionView
        self.collectionPrice = collectionPrice
        self.trackPrice = trackPrice
        if let artworkURLString = json["artworkUrl100"] as? String, let artwork = URL(string: artworkURLString) {
            self.artwork = artwork
        } else {
            self.artwork = nil
        }
        self.release = release
        self.durationMilliseconds = durationMilliseconds
    }
}

extension TelevisionEpisode: Media {
    public init?(json: [String: Any]) {
        guard
            let collectionId = json["collectionId"] as? Int,
            let trackId = json["trackId"] as? Int,
            let collectionName = json["collectionName"] as? String,
            let trackName = json["trackName"] as? String,
            let previewURLString = json["previewUrl"] as? String,
            let preview = URL(string: previewURLString),
            let trackViewURLString = json["trackViewUrl"] as? String,
            let trackView = URL(string: trackViewURLString),
            let description = json["longDescription"] as? String
        else {
                return nil
        }

        self.collectionId = collectionId
        self.trackId = trackId
        self.collectionName = collectionName
        self.trackName = trackName
        self.preview = preview
        self.trackView = trackView
        if
            let artworkURLString = (json["artworkUrl600"] as? String ?? json["artworkUrl100"] as? String),
            let artwork = URL(string: artworkURLString)
        {
            self.artwork = artwork
        } else {
            self.artwork = nil
        }
        self.description = description
        self.localPreview = nil
    }
}

extension Podcast: Media {
    public init?(json: [String: Any]) {
        guard
            let trackId = json["trackId"] as? Int,
            let collectionId = json["collectionId"] as? Int,
            let artistName = json["artistName"] as? String,
            let collectionName = json["collectionName"] as? String,
            let collectionViewString = json["collectionViewUrl"] as? String,
            let collectionView = URL(string: collectionViewString)
        else {
                return nil
        }
        self.trackId = trackId
        self.collectionId = collectionId
        self.collectionView = collectionView
        self.artistName = artistName
        self.collectionName = collectionName
        if let artworkURLString = json["artworkUrl100"] as? String, let artwork = URL(string: artworkURLString) {
            self.artwork = artwork
        } else {
            self.artwork = nil
        }
        self.primaryGenre = ""//primaryGenre
        self.primaryGenreId = "1"//primaryGenreId
    }
}

// MARK: Date Helpers

private let serviceDateFormatter: DateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return dateFormatter
}()
