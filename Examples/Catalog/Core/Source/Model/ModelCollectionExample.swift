import Pilot

// TODO:(wkiefer) These are subject to the final rename decisions from https://github.com/dropbox/pilot/issues/54.
public enum ModelCollectionExample: String {
    case filtered
    case sorted
}

extension ModelCollectionExample: Model {
    public var modelId: ModelId {
        return self.rawValue
    }
    public var modelVersion: ModelVersion {
        return ModelVersion.unit
    }
}
