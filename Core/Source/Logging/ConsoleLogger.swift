import Foundation

/// Logs to standard console.
public struct ConsoleLogger: Logger {

    // MARK: Init

    public init(minimumSeverity: Log.Severity = .warning) {
        self.minimumSeverity = minimumSeverity
    }

    // MARK: Public

    public var minimumSeverity: Log.Severity

    // MARK: Logger

    public func log(_ message: String, date: Date, severity: Log.Severity, category: Log.Category) {
        guard severity >= minimumSeverity else { return }

        var domain = ""
        if case .domain(let domainString) = category {
            domain = "\(domainString): "
        }
        // NOTE: `NSLog` will crash if the inline swift string contains percent-encoded data - so this code uses `%@`
        // explicitly for all incoming strings.
        NSLog("[%@] %@%@", severity.description.uppercased(), domain, message)
    }
}
