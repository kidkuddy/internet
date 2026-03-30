import Foundation
import os

enum Log {
    private static let subsystem = "com.kidkuddy.internet-tracker"
    private static let osLog = OSLog(subsystem: subsystem, category: "general")
    private static let logFileURL: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("InternetTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("app.log")
    }()

    static func info(_ message: String) {
        os_log(.info, log: osLog, "%{public}@", message)
        writeToFile("INFO", message)
    }

    static func error(_ message: String) {
        os_log(.error, log: osLog, "%{public}@", message)
        writeToFile("ERROR", message)
    }

    static func debug(_ message: String) {
        os_log(.debug, log: osLog, "%{public}@", message)
        writeToFile("DEBUG", message)
    }

    private static func writeToFile(_ level: String, _ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"

        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let handle = try? FileHandle(forWritingTo: logFileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
}
