import XCTest
@testable import Persistence
import Foundation

final class DatabaseTests: XCTestCase {
    func testCreateAndQuery() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_\(UUID().uuidString).db").path
        let db = try Database(path: dbPath)

        try db.execute("CREATE TABLE test (id TEXT PRIMARY KEY, name TEXT)")
        try db.insert(
            "INSERT INTO test (id, name) VALUES (?, ?)",
            params: [.text("1"), .text("hello")]
        )

        let rows = try db.query("SELECT * FROM test WHERE id = ?", params: [.text("1")])
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["name"]?.textValue, "hello")

        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testMigrationsRun() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_\(UUID().uuidString).db").path
        let db = try Database(path: dbPath)

        let runner = MigrationRunner(database: db)
        try runner.runAll()

        let tables = try db.query(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        )
        let tableNames = tables.compactMap { $0["name"]?.textValue }
        XCTAssertTrue(tableNames.contains("history"))
        XCTAssertTrue(tableNames.contains("bookmarks"))
        XCTAssertTrue(tableNames.contains("workspaces"))
        XCTAssertTrue(tableNames.contains("embeddings"))
        XCTAssertTrue(tableNames.contains("settings"))

        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testIdempotentMigrations() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_\(UUID().uuidString).db").path
        let db = try Database(path: dbPath)

        let runner = MigrationRunner(database: db)
        try runner.runAll()
        try runner.runAll() // Should not fail

        try? FileManager.default.removeItem(atPath: dbPath)
    }
}
