import Pilot

public struct CommonModelCollections {
    
    public static func makeTopics() -> ModelCollection {
        return StaticModelCollection(collectionId: "Topics", initialData: [
            Topic.modelCollections
        ])
    }
    
    public static func makeModelCollectionExamples() -> ModelCollection {
        return StaticModelCollection(collectionId: "ModelCollectionExamples", initialData: [
            ModelCollectionExample.filtered,
            ModelCollectionExample.sorted,
        ])
    }
}
