import Foundation

public struct MigrationRunner {
    private let db: Database

    public init(database: Database) {
        self.db = database
    }

    public func runAll() throws {
        try db.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at REAL NOT NULL
            )
        """)

        let applied = try db.query("SELECT version FROM schema_migrations ORDER BY version")
        let appliedVersions = Set(applied.compactMap { $0["version"]?.intValue })

        for migration in Self.migrations {
            if !appliedVersions.contains(migration.version) {
                try db.execute(migration.sql)
                try db.insert(
                    "INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)",
                    params: [.integer(migration.version), .real(Date().timeIntervalSince1970)]
                )
            }
        }
    }

    private static let migrations: [(version: Int, sql: String)] = [
        (1, """
            CREATE TABLE history (
                id TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                title TEXT,
                visited_at REAL NOT NULL,
                session_id TEXT,
                workspace_id TEXT,
                duration REAL
            );
            CREATE INDEX idx_history_url ON history(url);
            CREATE INDEX idx_history_visited ON history(visited_at DESC);
            CREATE INDEX idx_history_session ON history(session_id);
        """),

        (2, """
            CREATE TABLE bookmarks (
                id TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                title TEXT NOT NULL,
                folder_id TEXT,
                created_at REAL NOT NULL,
                FOREIGN KEY (folder_id) REFERENCES bookmark_folders(id)
            );
            CREATE TABLE bookmark_folders (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                parent_id TEXT,
                FOREIGN KEY (parent_id) REFERENCES bookmark_folders(id)
            );
            CREATE INDEX idx_bookmarks_folder ON bookmarks(folder_id);
        """),

        (3, """
            CREATE TABLE workspaces (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                panel_layout TEXT NOT NULL,
                tabs TEXT NOT NULL,
                created_at REAL NOT NULL,
                last_accessed_at REAL NOT NULL
            );
        """),

        (4, """
            CREATE TABLE embeddings (
                id TEXT PRIMARY KEY,
                source_type TEXT NOT NULL,
                source_id TEXT NOT NULL,
                vector BLOB NOT NULL,
                text_content TEXT,
                created_at REAL NOT NULL
            );
            CREATE INDEX idx_embeddings_source ON embeddings(source_type, source_id);
        """),

        (5, """
            CREATE TABLE settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
        """),
    ]
}
