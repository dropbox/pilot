import Pilot

struct TM: Model {
    // swiftlint:disable:next variable_name
    init(id: ModelId, version: Int) {
        self.modelId = id
        self.modelVersion = ModelVersion(hash: version)
    }

    let modelId: ModelId
    let modelVersion: ModelVersion

    static let A = TM(id: "A", version: 0)
    static let A_1 = TM(id: "A", version: 1)
    static let B = TM(id: "B", version: 0)
    static let B_1 = TM(id: "B", version: 1)
    static let C = TM(id: "C", version: 0)
    static let D = TM(id: "D", version: 0)
    static let E = TM(id: "E", version: 0)
    static let F = TM(id: "F", version: 0)
    static let G = TM(id: "G", version: 0)
}
