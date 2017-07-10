import Pilot

public enum Topic: String {
    case modelCollections
}

extension Topic: Model {
    public var modelId: ModelId {
        return self.rawValue
    }
    public var modelVersion: ModelVersion {
        return ModelVersion.unit
    }
}
