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
        return episode.artwork
    }

    public var description: String {
        return episode.description
    }

    public var localPreview: URL? {
        return episode.localPreview
    }

    // MARK: ViewModel

    public let context: Context

    public func action(_ event: ViewModelUserEvent) -> Action? {
        if case .select = event {
            return ViewMediaAction(url: episode.preview)
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
