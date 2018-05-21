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
        var mixer = ModelVersionMixer()
        mixer.mix(artistId)
        mixer.mix(collectionId)
        mixer.mix(trackId)
        mixer.mix(artistName)
        mixer.mix(collectionName)
        mixer.mix(trackName)
        mixer.mix(artistViewUrl.absoluteString)
        mixer.mix(collectionViewUrl.absoluteString)
        mixer.mix(trackViewUrl.absoluteString)
        mixer.mix(previewUrl.absoluteString)
        if let artwork = artworkUrl100 {
            mixer.mix(artwork.absoluteString)
        }
        mixer.mix(Float64(collectionPrice))
        mixer.mix(Float64(trackPrice))
        mixer.mix(releaseDate)
        mixer.mix(trackTimeMillis)
        if let trackNumber = trackNumber {
            mixer.mix(trackNumber)
        }
        if let trackCount = trackCount {
            mixer.mix(trackCount)
        }
        return mixer.result()
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
        var mixer = ModelVersionMixer()
        mixer.mix(collectionId)
        mixer.mix(trackId)
        mixer.mix(collectionName)
        mixer.mix(trackName)
        mixer.mix(trackViewUrl.absoluteString)
        mixer.mix(previewUrl.absoluteString)
        if let artwork = artworkUrl100 {
            mixer.mix(artwork.absoluteString)
        }
        mixer.mix(shortDescription)
        return mixer.result()
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
        var mixer = ModelVersionMixer()
        mixer.mix(collectionId)
        mixer.mix(trackId)
        mixer.mix(collectionName)
        mixer.mix(collectionViewUrl.absoluteString)
        if let artwork = artworkUrl100 {
            mixer.mix(artwork.absoluteString)
        }
        return mixer.result()
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

