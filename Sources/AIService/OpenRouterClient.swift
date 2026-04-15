import Foundation
import AetherCore
import SecureStorage

public final class OpenRouterClient: @unchecked Sendable {
    private let keychain: KeychainManager
    private let session: URLSession

    public init(keychain: KeychainManager = KeychainManager()) {
        self.keychain = keychain
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 4
        config.timeoutIntervalForRequest = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - API Key

    public var isConfigured: Bool {
        (try? keychain.loadString(key: AppConstants.Keychain.apiKeyAccount)) != nil
    }

    public func setAPIKey(_ key: String) throws {
        try keychain.save(key: AppConstants.Keychain.apiKeyAccount, string: key)
    }

    public func clearAPIKey() throws {
        try keychain.delete(key: AppConstants.Keychain.apiKeyAccount)
    }

    private func getAPIKey() throws -> String {
        guard let key = try keychain.loadString(key: AppConstants.Keychain.apiKeyAccount) else {
            throw OpenRouterError.noAPIKey
        }
        return key
    }

    // MARK: - Validate

    public func validateAPIKey(_ key: String) async throws -> Bool {
        var request = URLRequest(url: URL(string: "\(AppConstants.OpenRouter.baseURL)/models")!)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConstants.OpenRouter.httpReferer, forHTTPHeaderField: "HTTP-Referer")
        request.setValue(AppConstants.OpenRouter.appTitle, forHTTPHeaderField: "X-Title")

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }
        return httpResponse.statusCode == 200
    }

    // MARK: - Request Builder

    private func buildRequest(endpoint: String, body: Data) throws -> URLRequest {
        let apiKey = try getAPIKey()
        let url = URL(string: "\(AppConstants.OpenRouter.baseURL)\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConstants.OpenRouter.httpReferer, forHTTPHeaderField: "HTTP-Referer")
        request.setValue(AppConstants.OpenRouter.appTitle, forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 60

        return request
    }
}

// MARK: - LLMService

extension OpenRouterClient: LLMService {
    public func complete(prompt: String, model: String?, system: String?) async throws -> String {
        let selectedModel = model ?? AppConstants.Defaults.llmModel

        var messages: [[String: String]] = []
        if let system {
            messages.append(["role": "system", "content": system])
        }
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": selectedModel,
            "messages": messages,
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let request = try buildRequest(endpoint: AppConstants.OpenRouter.chatEndpoint, body: bodyData)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenRouterError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let choices = json?["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw OpenRouterError.invalidResponseFormat
        }

        return content
    }

    public func stream(prompt: String, model: String?, system: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let selectedModel = model ?? AppConstants.Defaults.llmModel

                    var messages: [[String: String]] = []
                    if let system {
                        messages.append(["role": "system", "content": system])
                    }
                    messages.append(["role": "user", "content": prompt])

                    let body: [String: Any] = [
                        "model": selectedModel,
                        "messages": messages,
                        "stream": true,
                    ]
                    let bodyData = try JSONSerialization.data(withJSONObject: body)

                    let request = try self.buildRequest(
                        endpoint: AppConstants.OpenRouter.chatEndpoint,
                        body: bodyData
                    )

                    let (bytes, response) = try await self.session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        throw OpenRouterError.invalidResponse
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if jsonString == "[DONE]" { break }
                            if let jsonData = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let delta = choices.first?["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                continuation.yield(content)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - EmbeddingService

extension OpenRouterClient: EmbeddingService {
    public func embed(texts: [String], model: String?) async throws -> [[Float]] {
        let selectedModel = model ?? AppConstants.Defaults.embeddingModel

        let body: [String: Any] = [
            "model": selectedModel,
            "input": texts,
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let request = try buildRequest(endpoint: AppConstants.OpenRouter.embeddingsEndpoint, body: bodyData)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenRouterError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let embeddings = json?["data"] as? [[String: Any]] else {
            throw OpenRouterError.invalidResponseFormat
        }

        return embeddings.compactMap { item in
            (item["embedding"] as? [NSNumber])?.map { Float(truncating: $0) }
        }
    }
}

// MARK: - Errors

public enum OpenRouterError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No OpenRouter API key configured. Add your key in Settings."
        case .invalidResponse:
            return "Invalid response from OpenRouter."
        case .invalidResponseFormat:
            return "Unexpected response format from OpenRouter."
        case .apiError(let code, let msg):
            return "OpenRouter API error (\(code)): \(msg)"
        }
    }
}
