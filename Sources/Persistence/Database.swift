import Foundation
#if canImport(SQLite3)
import SQLite3
#endif

public final class Database: @unchecked Sendable {
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.aether.database", qos: .userInitiated)

    public init(path: String) throws {
        let dir = (path as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let status = sqlite3_open_v2(path, &handle, flags, nil)
        guard status == SQLITE_OK, let h = handle else {
            let msg = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw DatabaseError.openFailed(msg)
        }
        self.db = h

        try execute("PRAGMA journal_mode = WAL")
        try execute("PRAGMA foreign_keys = ON")
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    // MARK: - Execute

    public func execute(_ sql: String) throws {
        try queue.sync {
            var errorMessage: UnsafeMutablePointer<CChar>?
            let status = sqlite3_exec(db, sql, nil, nil, &errorMessage)
            if status != SQLITE_OK {
                let msg = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                sqlite3_free(errorMessage)
                throw DatabaseError.executeFailed(msg)
            }
        }
    }

    // MARK: - Query

    public func query(_ sql: String, params: [DatabaseValue] = []) throws -> [[String: DatabaseValue]] {
        try queue.sync {
            var stmt: OpaquePointer?
            let status = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
            guard status == SQLITE_OK, let s = stmt else {
                let msg = String(cString: sqlite3_errmsg(db))
                throw DatabaseError.prepareFailed(msg)
            }
            defer { sqlite3_finalize(s) }

            for (index, param) in params.enumerated() {
                let i = Int32(index + 1)
                switch param {
                case .text(let v):
                    sqlite3_bind_text(s, i, (v as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                case .integer(let v):
                    sqlite3_bind_int64(s, i, Int64(v))
                case .real(let v):
                    sqlite3_bind_double(s, i, v)
                case .blob(let v):
                    _ = v.withUnsafeBytes { ptr in
                        sqlite3_bind_blob(s, i, ptr.baseAddress, Int32(v.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    }
                case .null:
                    sqlite3_bind_null(s, i)
                }
            }

            var rows: [[String: DatabaseValue]] = []
            let columnCount = sqlite3_column_count(s)

            while sqlite3_step(s) == SQLITE_ROW {
                var row: [String: DatabaseValue] = [:]
                for col in 0..<columnCount {
                    let name = String(cString: sqlite3_column_name(s, col))
                    let type = sqlite3_column_type(s, col)
                    switch type {
                    case SQLITE_TEXT:
                        row[name] = .text(String(cString: sqlite3_column_text(s, col)))
                    case SQLITE_INTEGER:
                        row[name] = .integer(Int(sqlite3_column_int64(s, col)))
                    case SQLITE_FLOAT:
                        row[name] = .real(sqlite3_column_double(s, col))
                    case SQLITE_BLOB:
                        let bytes = sqlite3_column_bytes(s, col)
                        if let ptr = sqlite3_column_blob(s, col) {
                            row[name] = .blob(Data(bytes: ptr, count: Int(bytes)))
                        } else {
                            row[name] = .null
                        }
                    default:
                        row[name] = .null
                    }
                }
                rows.append(row)
            }
            return rows
        }
    }

    // MARK: - Insert helper

    public func insert(_ sql: String, params: [DatabaseValue] = []) throws {
        _ = try query(sql, params: params)
    }
}

public enum DatabaseValue {
    case text(String)
    case integer(Int)
    case real(Double)
    case blob(Data)
    case null

    public var textValue: String? {
        if case .text(let v) = self { return v }
        return nil
    }

    public var intValue: Int? {
        if case .integer(let v) = self { return v }
        return nil
    }

    public var realValue: Double? {
        if case .real(let v) = self { return v }
        return nil
    }

    public var blobValue: Data? {
        if case .blob(let v) = self { return v }
        return nil
    }
}

public enum DatabaseError: Error, LocalizedError {
    case openFailed(String)
    case executeFailed(String)
    case prepareFailed(String)

    public var errorDescription: String? {
        switch self {
        case .openFailed(let m): return "Database open failed: \(m)"
        case .executeFailed(let m): return "SQL execution failed: \(m)"
        case .prepareFailed(let m): return "SQL prepare failed: \(m)"
        }
    }
}
