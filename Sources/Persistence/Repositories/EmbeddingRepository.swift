import Foundation
import AetherCore

public final class EmbeddingRepository: @unchecked Sendable {
    private let db: Database

    public init(database: Database) {
        self.db = database
    }

    public func insert(_ record: EmbeddingRecord) throws {
        let vectorData = record.vector.withUnsafeBufferPointer { ptr in
            Data(buffer: ptr)
        }
        try db.insert(
            """
            INSERT OR REPLACE INTO embeddings (id, source_type, source_id, vector, text_content, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            params: [
                .text(record.id.uuidString),
                .text(record.sourceType.rawValue),
                .text(record.sourceId.uuidString),
                .blob(vectorData),
                .text(record.textContent),
                .real(record.createdAt.timeIntervalSince1970),
            ]
        )
    }

    public func allEmbeddings(sourceType: EmbeddingSourceType? = nil) throws -> [EmbeddingRecord] {
        let sql: String
        let params: [DatabaseValue]
        if let st = sourceType {
            sql = "SELECT * FROM embeddings WHERE source_type = ? ORDER BY created_at DESC"
            params = [.text(st.rawValue)]
        } else {
            sql = "SELECT * FROM embeddings ORDER BY created_at DESC"
            params = []
        }
        let rows = try db.query(sql, params: params)
        return rows.compactMap(Self.rowToRecord)
    }

    public func delete(sourceId: UUID) throws {
        try db.insert(
            "DELETE FROM embeddings WHERE source_id = ?",
            params: [.text(sourceId.uuidString)]
        )
    }

    private static func rowToRecord(_ row: [String: DatabaseValue]) -> EmbeddingRecord? {
        guard
            let idStr = row["id"]?.textValue,
            let id = UUID(uuidString: idStr),
            let sourceTypeStr = row["source_type"]?.textValue,
            let sourceType = EmbeddingSourceType(rawValue: sourceTypeStr),
            let sourceIdStr = row["source_id"]?.textValue,
            let sourceId = UUID(uuidString: sourceIdStr),
            let vectorData = row["vector"]?.blobValue,
            let textContent = row["text_content"]?.textValue,
            let createdAt = row["created_at"]?.realValue
        else { return nil }

        let vector = vectorData.withUnsafeBytes { ptr in
            Array(ptr.bindMemory(to: Float.self))
        }

        return EmbeddingRecord(
            id: id,
            sourceType: sourceType,
            sourceId: sourceId,
            vector: vector,
            textContent: textContent,
            createdAt: Date(timeIntervalSince1970: createdAt)
        )
    }
}
