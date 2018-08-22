import Pilot

public struct TelevisionEpisodeViewModel: ViewModel {
    public init(model: Model, context: Context) {
        self.episode = model.typedModel()
        self.context = context
    }

    // MARK: Public

    public var name: String {
        return episode.trackName
    }

    public var collectionName: String {
        return episode.collectionName
    }

    public var artwork: URL? {
        return episode.artworkUrl100
    }

    public var description: String {
        return episode.shortDescription
    }

    public var localPreview: URL? {
        // Not implemented.
        return nil
    }

    // MARK: ViewModel

    public let context: Context

    public func actionForUserEvent(_ event: ViewModelUserEvent) -> Action? {
        if case .select = event {
            return ViewMediaAction(url: episode.previewUrl)
        }
        return nil
    }

    // MARK: Private

    private let episode: TelevisionEpisode
}

extension TelevisionEpisode: ViewModelConvertible {
    public func viewModelWithContext(_ context: Context) -> ViewModel {
        return TelevisionEpisodeViewModel(model: self, context: context)
    }
}
