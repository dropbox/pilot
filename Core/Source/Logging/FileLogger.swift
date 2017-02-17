import Foundation

/// `FileLogger` is a Logger that simply forwards log messages to a file. The url for the file is specified at init.
/// FileLogger is a class and not a struct because it maintains a var bytesWritten, so that it can enforce a maxFileSize
/// limitation.
public final class FileLogger: Logger {

    // MARK: Init

    public init(prefixURL: URL, maxFileSize: Int = 128000, maxFiles: Int = 3) {
        self.outputPrefixURL = prefixURL
        self.maxFileSize = maxFileSize
        self.maxFiles = maxFiles
        setupStream()
    }

    // MARK: Public

    /// Called whenever logger starts a new file, passes in the index postpended to the prefix URL.
    public var startedNewFile: (Int) -> Void = { _ in }

    public func close() {
        outputStream?.close()
    }

    public let maxFileSize: Int

    // MARK: Logger

    public func log(_ message: String, date: Date, severity: Log.Severity, category: Log.Category) {
        guard !failed else { return }
        let stringToLog = "\(date)\t\(category)\t\(severity)\t\(message)\r"
        let data = stringToLog.data(using: String.Encoding.utf8)!
        bytesWritten = bytesWritten + data.count
        if bytesWritten > maxFileSize {
            rotate()
            bytesWritten = data.count
        }
        outputStream?.write((data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), maxLength: data.count)
    }

    // MARK: Private

    private var failed = false
    private var currentFileIndex = 0
    private let maxFiles: Int
    private var nextFileIndex: Int {
        return (currentFileIndex + 1) % maxFiles
    }

    private let outputPrefixURL: URL
    private var currentURL: URL? {
        return outputPrefixURL.appendingPathExtension("\(currentFileIndex)")
    }

    private var outputStream: OutputStream?
    private var bytesWritten: Int = 0

    /// Advance current file, delete
    private func rotate() {
        defer {
            // Always close old stream even if we can't open the new one.
            setupStream()
        }
        currentFileIndex = nextFileIndex
        guard let newURL = currentURL else { return }
        if FileManager.default.fileExists(atPath: newURL.path ) {
            do {
                try FileManager.default.removeItem(at: newURL)
            } catch {
                failed = true
                Log.error(message: "FileLogger unable to remove existing log to rotate, dropping new logs")
            }
        }
    }

    /// Set up outputStream at new file, closing old stream if necessary
    private func setupStream() {
        outputStream?.close()
        outputStream = nil
        guard let URL = currentURL , !failed else { return }
        let newStream = OutputStream(url: URL, append: true)
        newStream?.open()
        outputStream = newStream
        startedNewFile(currentFileIndex)
    }
}
