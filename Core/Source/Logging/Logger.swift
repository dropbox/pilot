import Foundation

/// `Logger` is a place where one sends a log for processing
public protocol Logger {
    func log(_ message: String, date: Date, severity: Log.Severity, category: Log.Category)
}

public typealias LoggerToken = Int

/// `Log` is a singleton which handles log messages client code and forwards those to Loggers which are registered with
/// Log via the addLogger function.
///
/// Callers should use `Log` to invoke logging as in these examples:
///
/// ```swift
/// Log.info("This is a message with no category specified")
/// Log.warning(.Domain("dropbox.notifications"), "This is a warning in a specific category")
/// Log.metadata(.Domain("log"), "Application Launched")
/// ```
///
/// Metadata shouldn't be used other than for basic log information which is meant to be included with every log
///   for example, system config information, Date/time
public struct Log {
    public enum Severity: Int, CustomStringConvertible, Comparable {

        case metadata = 5
        case error = 4
        case warning = 3
        case info = 2
        case verbose = 1

        public var description: String {
            switch self {
                case .error:
                    return "error"
                case .warning:
                    return "warning"
                case .info:
                    return "info"
                case .verbose:
                    return "verbose"
                case .metadata:
                    return "metadata"
            }
        }
    }

    public enum Category: ExpressibleByStringLiteral {
        public typealias UnicodeScalarLiteralType = StringLiteralType
        public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

        // Domain is a String which specifies what the log is about, and is a period-delimited sequence specifying a
        // hierarchy.  For example, it might be "eventsource", "eventsource.calendar", or
        // "eventsource.calendar.eventcheck"
        // LoggingEventObservers can use the Domain as a way to filter logs of interest
        // using an array of strings for this allows hierarchical filter settings:  i.e. log
        //     any Error,
        //     any Warning under "eventsource"
        //     any Info under "eventsource.calendar"
        //     any Verbose under "eventsource.calendar.eventcheck"
        case domain(String)
        case none

        public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
            self = .domain("\(value)")
        }

        public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
            self = .domain(value)
        }

        public init(stringLiteral value: StringLiteralType) {
            self = .domain(value)
        }
    }

    static public func verbose(_ category: Category = .none, message: String) {
        log(.verbose, category: category, message: message)
    }

    static public func info(_ category: Category = .none, message: String) {
        log(.info, category: category, message: message)
    }

    static public func warning(_ category: Category = .none, message: String) {
        log(.warning, category: category, message: message)
    }

    static public func error(_ category: Category = .none, message: String) {
        log(.error, category: category, message: message)
    }

    static public func metadata(_ category: Category = .none, message: String) {
        log(.metadata, category: category, message: message)
    }

    static public func fatal(_ category: Category = .none, message: String) -> Never {
        log(.error, category: category, message: message)
        fatalError(message)
    }

    static public func removeLogger(_ token: LoggerToken) {
        Async.on(loggingQueue) {
            loggers[token] = nil
        }
    }

    static public func addLogger(_ logger: Logger) -> LoggerToken {
        let token = nextLoggerToken
        nextLoggerToken += 1
        Async.on(loggingQueue) {
            loggers[token] = logger
        }
        return token
    }

    // MARK: Internal

    /// Logging shouldn't have a callback mechanism to signal when log processing is finished, because that wouldn't
    /// be performant.  However, when running tests, there is a need for waiting until a previous logging operation
    /// is complete.  To do this, one can schedule a sentinel on the serial queues used for logging, and when
    /// the sentinel comes through, one can be sure that a previous logging request should have completed
    static internal func sendSentinelThroughQueue(_ sentinel: String, completion: @escaping (String) -> Void) {
        Async.on(loggingQueue) {
            completion(sentinel)
        }
    }

    // MARK: Private

    static private func log(_ severity: Severity, category: Category, message: String) {
        Async.on(loggingQueue) {
            let date = Date()
            for (_, logger) in loggers {
                logger.log(message, date: date, severity: severity, category: category)
            }
        }
    }

    static private let loggingQueue: Queue = .custom(DispatchQueue(
        label: "com.dropbox.pilot.log.loggingQ",
        attributes: []
    ))

    static private var nextLoggerToken: Int = 0
    static private var loggers: [LoggerToken: Logger] = [:]
}

public func < (lhs: Log.Severity, rhs: Log.Severity) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

// MARK: Assert Functions

#if DEBUG
public func assertionFailureWithLog(
    category: Log.Category = .none,
    message: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    Log.error(category, message: message)
    assertionFailure(message, file: file, line: line)
}
public func assertWithLog(_ condition: Bool,
    _ category: Log.Category = .none,
    message: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    if !condition {
        Log.error(category, message: message)
    }
    assert(condition, message, file: file, line: line)
}
#else
public func assertionFailureWithLog(_ category: Log.Category = .none, message: String) {
    Log.error(category, message: message)
    assertionFailure(message)
}
public func assertWithLog(_ condition: Bool, _ category: Log.Category = .none, message: String) {
    if !condition {
        Log.error(category, message: message)
    }
    assert(condition, message)
}
#endif
