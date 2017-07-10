import Pilot

public struct CommonModelCollections {
    
    public static func makeTopics() -> ModelCollection {
        return StaticModelCollection(collectionId: "Topics", initialData: [
            Topic.modelCollections
        ])
    }
}
