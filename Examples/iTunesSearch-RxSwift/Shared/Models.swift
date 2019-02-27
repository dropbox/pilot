import Foundation
import Pilot

public struct Song: Model, Decodable {
    public var artistId: Int
    public var collectionId: Int
    public var trackId: Int
    public var artistName: String
    public var collectionName: String
    public var trackName: String
    public var artistViewUrl: URL
    public var collectionViewUrl: URL
    public var trackViewUrl: URL
    public var previewUrl: URL
    public var artworkUrl100: URL?
    public var collectionPrice: Float
    public var trackPrice: Float
    public var releaseDate: String
    public var trackTimeMillis: Int
    public var trackNumber: Int?
    public var trackCount: Int?

    // MARK: Model

    public var modelId: ModelId {
        return String(trackId)
    }

    public var modelVersion: ModelVersion {
        var hasher = Hasher()
        hasher.combine(artistId)
        hasher.combine(collectionId)
        hasher.combine(trackId)
        hasher.combine(artistName)
        hasher.combine(collectionName)
        hasher.combine(trackName)
        hasher.combine(artistViewUrl)
        hasher.combine(collectionViewUrl)
        hasher.combine(trackViewUrl)
        hasher.combine(previewUrl)
        if let artwork = artworkUrl100 {
            hasher.combine(artwork)
        }
        hasher.combine(collectionPrice)
        hasher.combine(trackPrice)
        hasher.combine(releaseDate)
        hasher.combine(trackTimeMillis)
        if let trackNumber = trackNumber {
            hasher.combine(trackNumber)
        }
        if let trackCount = trackCount {
            hasher.combine(trackCount)
        }
        return ModelVersion(hash: hasher.finalize())
    }
}

public struct TelevisionEpisode: Model, Decodable {
    public var trackId: Int
    public var collectionId: Int
    public var collectionName: String
    public var trackName: String
    public var trackViewUrl: URL
    public var previewUrl: URL
    public var artworkUrl100: URL?
    public var shortDescription: String

    // MARK: Model

    public var modelId: ModelId {
        return String(trackId)
    }

    public var modelVersion: Pilot.ModelVersion {
        var hasher = Hasher()
        hasher.combine(collectionId)
        hasher.combine(trackId)
        hasher.combine(collectionName)
        hasher.combine(trackName)
        hasher.combine(trackViewUrl)
        hasher.combine(previewUrl)
        if let artwork = artworkUrl100 {
            hasher.combine(artwork)
        }
        hasher.combine(shortDescription)
        return ModelVersion(hash: hasher.finalize())
    }
}

public struct Podcast: Model, Decodable {
    public var trackId: Int
    public var collectionId: Int
    public var artistName: String
    public var collectionName: String
    public var collectionViewUrl: URL
    public var artworkUrl100: URL?

    // MARK: Model

    public var modelId: ModelId {
        return String(trackId)
    }

    public var modelVersion: ModelVersion {
        var hasher = Hasher()
        hasher.combine(collectionId)
        hasher.combine(trackId)
        hasher.combine(collectionName)
        hasher.combine(collectionViewUrl)
        if let artwork = artworkUrl100 {
            hasher.combine(artwork)
        }
        return ModelVersion(hash: hasher.finalize())
    }
}

// MARK: iTunes Search Service Response JSON

public struct SearchServiceResponse: Decodable {
    public var resultCount: Int
    public var results: [Result]

    public struct Result: Decodable {
        public enum Model {
            case song(Song)
            case podcast(Podcast)
            case televisionEpisode(TelevisionEpisode)
            case unknown
        }
        public var model: Model

        public enum Keys: String, CodingKey {
            case kind
        }

        public init(from: Decoder) {
            do {
                let container = try from.container(keyedBy: Keys.self)
                let kind: String = try container.decode(String.self, forKey: Keys.kind)
                self.model = .unknown

                switch kind {
                case "song":
                    let song = try Song(from: from)
                    self.model = .song(song)
                case "podcast":
                    let podcast = try Podcast(from: from)
                    self.model = .podcast(podcast)
                case "tv-episode":
                    let episode = try TelevisionEpisode(from: from)
                    self.model = .televisionEpisode(episode)
                default:
                    self.model = .unknown
                }
            } catch {
                self.model = .unknown
            }
        }
    }
}

// MARK: Media

/// Common protocol representing a search result media.
public protocol Media: Model {}

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


