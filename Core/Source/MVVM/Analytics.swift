public protocol AnalyticsEvent {
    var name: String { get }
    var properties: [String: Any] { get }
}

public enum AnalyticsPropertyValueType {
    case bool(Bool)
    case string(String)
    case int(Int)
    case float(Float)
    case array([AnalyticsPropertyValueType])
    case map([String: AnalyticsPropertyValueType])
}

public struct SendAnalyticsEventAction: Action {
    public init(event: AnalyticsEvent) {
        self.event = event
    }

    public var event: AnalyticsEvent
}

public struct AnalyticsEventWrappedAction: Action {
    public init(event: AnalyticsEvent, action: Action) {
        self.event = event
        self.action = action
    }

    public var event: AnalyticsEvent
    public var action: Action
}
