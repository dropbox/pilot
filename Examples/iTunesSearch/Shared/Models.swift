import Foundation
import Pilot

public enum TrackKind: String {
    case televisionEpisode = "tv-episode"
    case song = "song"
    case podcast = "podcast"

    var modelType: Media.Type {
        switch self {
        case .televisionEpisode:
            return TelevisionEpisode.self
        case .song:
            return Song.self
        case .podcast:
            return Podcast.self
        }
    }
}

public struct Song: Model {
    public var artistId: Int
    public var collectionId: Int
    public var trackId: Int
    public var artistName: String
    public var collectionName: String
    public var trackName: String
    public var artistView: URL
    public var collectionView: URL
    public var trackView: URL
    public var preview: URL
    public var artwork: URL?
    public var collectionPrice: Float
    public var trackPrice: Float
    public var release: Date
    public var durationMilliseconds: Int
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
        mixer.mix(artistView.absoluteString)
        mixer.mix(collectionView.absoluteString)
        mixer.mix(trackView.absoluteString)
        mixer.mix(preview.absoluteString)
        if let artwork = artwork {
            mixer.mix(artwork.absoluteString)
        }
        mixer.mix(Float64(collectionPrice))
        mixer.mix(Float64(trackPrice))
        mixer.mix(release.timeIntervalSince1970)
        mixer.mix(durationMilliseconds)
        if let trackNumber = trackNumber {
            mixer.mix(trackNumber)
        }
        if let trackCount = trackCount {
            mixer.mix(trackCount)
        }
        return mixer.result()
    }
}

public struct TelevisionEpisode: Model {
    public var trackId: Int
    public var collectionId: Int
    public var collectionName: String
    public var trackName: String
    public var trackView: URL
    public var preview: URL
    public var artwork: URL?
    public var description: String
    public var localPreview: URL?

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
        mixer.mix(trackView.absoluteString)
        mixer.mix(preview.absoluteString)
        if let artwork = artwork {
            mixer.mix(artwork.absoluteString)
        }
        mixer.mix(description)
        return mixer.result()
    }
}

public struct Podcast: Model {
    public var trackId: Int
    public var collectionId: Int
    public var artistName: String
    public var collectionName: String
    public var collectionView: URL
    public var artwork: URL?
    public var primaryGenre: String
    public var primaryGenreId: String

    // MARK: Model

    public var modelId: ModelId {
        return String(trackId)
    }

    public var modelVersion: ModelVersion {
        var mixer = ModelVersionMixer()
        mixer.mix(collectionId)
        mixer.mix(trackId)
        mixer.mix(collectionName)
        mixer.mix(collectionView.absoluteString)
        if let artwork = artwork {
            mixer.mix(artwork.absoluteString)
        }
        mixer.mix(primaryGenre)
        mixer.mix(primaryGenreId)
        return mixer.result()
    }
}
