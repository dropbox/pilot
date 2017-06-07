import Foundation

extension NSIndexSet {
    convenience init(from array: [Int]) {
        var s = IndexSet()
        for e in array {
            s.insert(e)
        }
        self.init(indexSet: s)
    }
}

extension ModelPath {
    init(from: (Int, Int)) {
        let (sectionIndex, itemIndex) = from
        self.init(sectionIndex: sectionIndex, itemIndex: itemIndex)
    }
}

/// Struct which represents the difference between one set of models and another.
/// - Note: Updates are peformed last and should be expressed with correct IndexPath after the other events (insertions,
/// deletions, moves) have been applied.
/// - Note: The `from` IndexPath for `movedIndexPaths` should not take into account insertions or deletions, but `to`
/// should.
/// - Note: `removedModelPaths` does not contain any paths that would be removed by `removedSections`.
/// - Note: Per the docs for CollectionView.insertSection, it doesn't seem necessary to call insertItems for items in the
///   new section, but it doesn't seem to hurt either, so the diff engine doesn't elide them.
///
/// Here are the rules for how the indices interact:
/// - deletions are processed first, and deletion indices are relative to the initial collection
///   (that is, delete [1, 2], not [1, 1])
/// - insertions are processed next, and the indices should be adjusted based on deletions _but not other insertions_
/// - moves: the from: should be the index prior to deletes and inserts, but the to: field uses the same index as inserts
/// - updates: updated indices get reloaded after everything else is applied
///
/// This data structure does not assume moves are also updates.  If an item stays in place but the version changes then it's
/// an update.  If it moves position but the version differs, it's a move.  If both, it's both a move and then an update.
public struct CollectionEventUpdates {
    public var removedSections: [Int] = []
    public var addedSections: [Int] = []
    // The diff algorithm does not move sections around at this time.  If models had IDs,
    // moving sections would be possible.

    public var removedModelPaths = [ModelPath]()
    public var addedModelPaths = [ModelPath]()
    public var movedModelPaths = [MovedModel]()
    public var updatedModelPaths = [ModelPath]()

    // The following two properties are computed to work around bugs in UICollectionView and NSCollectionView
    // where the first item added to a section or last item removed from a section can cause a crash.

    /// Whether any section had its first item added.
    public var containsFirstAddInSection = false

    /// Whether any section had its last item removed.
    public var containsLastRemoveInSection = false

    /// The set of ModelIds that have been removed from the collection.
    /// Useful for clearing model caches.
    public var removedModelIds = [ModelId]()

    public init() {}

    public var hasUpdates: Bool {
        if !removedModelPaths.isEmpty {
            return true
        }
        if !addedModelPaths.isEmpty {
            return true
        }
        if !movedModelPaths.isEmpty {
            return true
        }
        if !updatedModelPaths.isEmpty {
            return true
        }
        if !addedSections.isEmpty {
            return true
        }
        if !removedSections.isEmpty {
            return true
        }
        return false
    }
}

private struct ModelInfo {
    var paths: [ModelPath]
    var id: ModelId
    var version: ModelVersion
}

private struct ModelState {
    let id: ModelId
    let version: ModelVersion
    var active: Bool
}

private func logState(_ prefix: String, _ state: [[ModelState]]) {
    Swift.print(prefix)
    for section in state {
        let entries = section.map { "\($0.id) - \($0.version)" }.joined(separator: ", ")
        Swift.print("  [ \(entries) ]")
    }
}

public struct DiffEngine {

    public init() {}

    /// Given a new set of models, returns a `CollectionEventUpdates` representing the differences
    /// between the old set and the new set.
    public mutating func update(_ models: [[Model]], debug: Bool = false) -> CollectionEventUpdates {
        var newModelInfo: [ModelId: ModelInfo] = [:]

        var updates = CollectionEventUpdates()
        var newState = [[ModelState]]()

        // Access the ID and version properties of all of the models in one pass, setting up our data structures.
        for (sectionIndex, section) in models.enumerated() {
            newState.append([])
            for (modelIndex, model) in section.enumerated() {
                let path = ModelPath(sectionIndex, modelIndex)

                // TODO(ca): This is two dynamic dispatches per model.  Introduce an idAndVersion call to fetch both.
                let id = model.modelId
                let version = model.modelVersion

                if var info = newModelInfo[id] {
                    // TODO(ca): enable this assertion when Pilot has a "stabilize" step after all collections have updated.
                    // Updates need to be coalesced so the UI never sees intermediate states.
                    //precondition(info.version == version, "Two models have same ID but different versions!")
                    info.paths.append(path)
                    newModelInfo[id] = info
                } else {
                    newModelInfo[id] = ModelInfo(paths: [path], id: id, version: version)
                }

                newState[sectionIndex].append(ModelState(
                    id: id,
                    version: version,
                    active: true
                ))
            }
        }

        if debug {
            logState("oldState", oldState)
            logState("newState", newState)
        }

        updates.removedModelIds = Array(Set(oldModelInfo.keys).subtracting(Set(newModelInfo.keys)))

        // First, make sure there are the right number of sections.  This code always adds or removes sections
        // from the end.  In the future, if models themselves had IDs, it would be possible to support
        // section moves or section insertions or deletions anywhere.
        if oldState.count < models.count {
            let range = oldState.count..<models.count
            updates.addedSections = [Int](range)
        } else if models.count < oldState.count {
            let range = models.count..<oldState.count
            updates.removedSections = [Int](range)
        }

        var stragglers: [ModelPath] = []

        // Since sections don't have IDs, this code keeps the same section cursor on the left and right.
        // If models had IDs this code could be smarter.
        var currentSection = 0
        while currentSection < newState.count {
            let oldSectionCount = (currentSection < oldState.count) ? oldState[currentSection].count : 0
            let newSectionCount = newState[currentSection].count

            updates.containsFirstAddInSection = updates.containsFirstAddInSection ||
                (oldSectionCount == 0 && newSectionCount != 0)
            updates.containsLastRemoveInSection = updates.containsLastRemoveInSection ||
                (oldSectionCount != 0 && newSectionCount == 0)

            // q - current physical position in old section
            // t - physical output position in new section
            var q = 0
            var t = 0

            func moveOrInsert(_ oldForNew: ModelInfo) {
                // find first path that's active
                var activePath: ModelPath?
                for path in oldForNew.paths {
                    if oldState[path.sectionIndex][path.itemIndex].active {
                        activePath = path
                        break
                    }
                }
                if let activePath = activePath, activePath.sectionIndex < newState.count {
                    updates.movedModelPaths.append(MovedModel(
                        from: activePath,
                        to: ModelPath(currentSection, t)))
                    if .some(oldForNew.version) != newModelInfo[oldForNew.id]?.version {
                        updates.updatedModelPaths.append(ModelPath(currentSection, t))
                    }
                    oldState[activePath.sectionIndex][activePath.itemIndex].active = false
                    t += 1
                } else {
                    updates.addedModelPaths.append(ModelPath(currentSection, t))
                    t += 1
                }
            }

            while true {
                if q < oldSectionCount && t < newSectionCount {
                    let oldMS = oldState[currentSection][q]
                    let newMS = newState[currentSection][t]

                    // already been consumed by another delete or move
                    if !oldMS.active {
                        q += 1
                        continue
                    }

                    if oldMS.id == newMS.id {
                        // consumed now
                        oldState[currentSection][q].active = false
                        
                        if oldMS.version != newMS.version {
                            updates.updatedModelPaths.append(ModelPath(currentSection, t))
                        }

                        q += 1
                        t += 1
                    } else {
                        switch (newModelInfo[oldMS.id], oldModelInfo[newMS.id]) {
                        // is the thing on the left on the right?  if not, delete
                        case (.none, _):
                            updates.removedModelPaths.append(ModelPath(currentSection, q))
                            oldState[currentSection][q].active = false
                            q += 1
                        // is the thing on the right on the left?
                        case (_, .none):
                            updates.addedModelPaths.append(ModelPath(currentSection, t))
                            t += 1
                        case (_, .some(let oldForNew)):
                            moveOrInsert(oldForNew)
                        }
                        continue
                    }

                } else if q < oldSectionCount {
                    stragglers.append(ModelPath(currentSection, q))
                    q += 1
                } else if t < newSectionCount {
                    let newMS = newState[currentSection][t]
                    switch oldModelInfo[newMS.id] {
                    case .none:
                        updates.addedModelPaths.append(ModelPath(currentSection, t))
                        t += 1
                    case .some(let oldForNew):
                        moveOrInsert(oldForNew)
                    }

                } else {
                    break
                }
            }

            currentSection += 1
        }

        for straggler in stragglers {
            let oldMS = oldState[straggler.sectionIndex][straggler.itemIndex]
            if oldMS.active {
                updates.removedModelPaths.append(straggler)
            }
        }

        oldState = newState
        oldModelInfo = newModelInfo

        return updates
    }

    private var oldState: [[ModelState]] = []
    private var oldModelInfo: [ModelId: ModelInfo] = [:]
}
