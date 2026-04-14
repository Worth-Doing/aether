import Foundation

public protocol LLMService: Sendable {
    func complete(prompt: String, model: String?, system: String?) async throws -> String
    func stream(prompt: String, model: String?, system: String?) -> AsyncThrowingStream<String, Error>
}

extension LLMService {
    public func complete(prompt: String) async throws -> String {
        try await complete(prompt: prompt, model: nil, system: nil)
    }

    public func stream(prompt: String) -> AsyncThrowingStream<String, Error> {
        stream(prompt: prompt, model: nil, system: nil)
    }
}
