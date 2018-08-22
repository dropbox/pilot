import Foundation
import Pilot

/// Action which pushes a view controller with a web view loading the given URL.
public struct ViewURLAction: Action {

    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}

/// Action which pushes a fullscreen media playback UI for the given URL.
public struct ViewMediaAction: Action {

    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}
