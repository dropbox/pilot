import Pilot

public struct File: Model {
    public var url: URL

    public var modelId: ModelId {
        return ModelId(url.absoluteString.hashValue)
    }

    public var modelVersion: ModelVersion {
        return .unit
    }
}
