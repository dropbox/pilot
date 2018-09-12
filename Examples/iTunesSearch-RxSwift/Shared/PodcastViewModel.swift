import Pilot

public struct PodcastViewModel: ViewModel {
    public init(model: Model, context: Context) {
        self.podcast = model.typedModel()
        self.context = context
    }

    // MARK: Public

    public var name: String {
        return podcast.collectionName
    }

    public var artistName: String {
        return podcast.artistName
    }

    public var artwork: URL? {
        return podcast.artworkUrl100
    }

    // MARK: ViewModel

    public let context: Context

    public func actionForUserEvent(_ event: ViewModelUserEvent) -> Action? {
        if case .select = event {
            return ViewURLAction(url: podcast.collectionViewUrl)
        }
        return nil
    }

    // MARK: Private

    private let podcast: Podcast
}

extension Podcast: ViewModelConvertible {
    public func viewModelWithContext(_ context: Context) -> ViewModel {
        return PodcastViewModel(model: self, context: context)
    }
}
