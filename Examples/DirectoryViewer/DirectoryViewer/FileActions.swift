import Pilot

public struct OpenFilesAction: Action {
    public init(urls: [URL]) {
        self.urls = urls
    }

    public var urls: [URL]
}
