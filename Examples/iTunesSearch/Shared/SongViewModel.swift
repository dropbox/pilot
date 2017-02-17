import Pilot

public struct SongViewModel: ViewModel {
    public init(model: Model, context: Context) {
        self.song = model.typedModel()
        self.context = context
    }

    // MARK: Public

    public var name: String {
        return song.trackName
    }

    public var description: String {
        if let number = song.trackNumber {
            if let count = song.trackCount {
                return "Track \(number)/\(count) · \(collectionName)"
            } else {
                return "Track \(number) · \(collectionName)"
            }
        } else {
            return collectionName
        }
    }

    public var collectionName: String {
        return song.collectionName
    }

    public var duration: String {
        let totalSeconds = song.durationMilliseconds / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = (totalSeconds % 60)
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return String(format: "%02d", seconds)
        }
    }

    public var artwork: URL? {
        return song.artwork
    }

    // MARK: ViewModel

    public let context: Context

    public func handleUserEvent(_ event: ViewModelUserEvent) {
        if case .select = event {
            ViewMediaAction(url: song.preview).send(from: context)
        }
    }

    // MARK: Private

    private let song: Song
}

extension Song: ViewModelConvertible {
    public func viewModelWithContext(_ context: Context) -> ViewModel {
        return SongViewModel(model: self, context: context)
    }
}
