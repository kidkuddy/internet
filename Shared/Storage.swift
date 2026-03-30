import Foundation
import SQLite3

final class Storage {
    private var db: OpaquePointer?
    private let dbPath: String

    init() {
        // Use App Group container so widget and host app share the same db
        let containerURL: URL
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "7PJ2KBXD4T.com.kidkuddy.internet-tracker.group"
        ) {
            containerURL = groupURL
        } else {
            // Fallback to Application Support
            containerURL = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!.appendingPathComponent("InternetTracker", isDirectory: true)
        }

        try? FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        dbPath = containerURL.appendingPathComponent("usage.db").path
    }

    func initialize() {
        Log.info("Opening database at \(dbPath)")
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            Log.error("Failed to open database at \(dbPath)")
            return
        }

        let createTable = """
            CREATE TABLE IF NOT EXISTS usage (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL NOT NULL,
                bytes_in INTEGER NOT NULL,
                bytes_out INTEGER NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_usage_timestamp ON usage(timestamp);
        """

        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, createTable, nil, nil, &errMsg) != SQLITE_OK {
            if let msg = errMsg {
                Log.error("SQL error: \(String(cString: msg))")
                sqlite3_free(msg)
            }
        }
    }

    func recordUsage(bytesIn: UInt64, bytesOut: UInt64, at date: Date) {
        let sql = "INSERT INTO usage (timestamp, bytes_in, bytes_out) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, date.timeIntervalSince1970)
        sqlite3_bind_int64(stmt, 2, Int64(bitPattern: bytesIn))
        sqlite3_bind_int64(stmt, 3, Int64(bitPattern: bytesOut))

        sqlite3_step(stmt)
    }

    func totalUsage(since date: Date) -> (bytesIn: UInt64, bytesOut: UInt64) {
        let sql = """
            SELECT COALESCE(SUM(bytes_in), 0), COALESCE(SUM(bytes_out), 0)
            FROM usage WHERE timestamp >= ?
        """
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return (0, 0) }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, date.timeIntervalSince1970)

        guard sqlite3_step(stmt) == SQLITE_ROW else { return (0, 0) }

        let bytesIn = UInt64(bitPattern: sqlite3_column_int64(stmt, 0))
        let bytesOut = UInt64(bitPattern: sqlite3_column_int64(stmt, 1))
        return (bytesIn, bytesOut)
    }

    deinit {
        sqlite3_close(db)
    }
}
