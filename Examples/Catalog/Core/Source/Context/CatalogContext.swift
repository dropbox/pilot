import Pilot

public final class CatalogContext: Context {
    
    // MARK: Context

    public override func newScope() -> CatalogContext {
        return CatalogContext(parentScope: self, navigatingUserEvents: navigatingUserEvents)
    }
}
