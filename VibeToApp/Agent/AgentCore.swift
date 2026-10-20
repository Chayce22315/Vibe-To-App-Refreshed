import Foundation

enum AgentMode: String {
    case cloud, local, hybrid
}

protocol AIProvider {
    func generate(prompt: String) async throws -> String
}

private struct CompletionRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

private struct CompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
    struct APIError: Decodable {
        let message: String?
    }
    let error: APIError?
}

/// Calls an OpenAI-compatible endpoint when configured. If no provider is
/// available, it falls back honestly to a local planning stub.
struct AgentCore {
    func respond(to prompt: String) async -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "give me an idea to work with and we'll get started." }

        let defaults = UserDefaults.standard
        let mode = AgentMode(rawValue: defaults.string(forKey: "aiMode") ?? "hybrid") ?? .hybrid
        let cloudURL = defaults.string(forKey: "cloudProviderBaseURL") ?? ""
        let cloudModel = defaults.string(forKey: "cloudProviderModel") ?? ""
        let localURL = defaults.string(forKey: "localProviderBaseURL") ?? "http://127.0.0.1:8080/v1"

        do {
            switch mode {
            case .cloud:
                guard !cloudURL.isEmpty else { return demoReply(trimmed, note: "cloud endpoint is not configured") }
                return try await request(baseURL: cloudURL, model: cloudModel.isEmpty ? "default" : cloudModel, prompt: trimmed, key: KeychainStore.get("cloud-api-key"))
            case .local:
                return try await request(baseURL: localURL, model: "blank", prompt: trimmed, key: KeychainStore.get("local-provider-token"))
            case .hybrid:
                if !cloudURL.isEmpty {
                    do {
                        return try await request(baseURL: cloudURL, model: cloudModel.isEmpty ? "default" : cloudModel, prompt: trimmed, key: KeychainStore.get("cloud-api-key"))
                    } catch {
                        // If cloud is unavailable, try the configured local endpoint.
                    }
                }
                return try await request(baseURL: localURL, model: "blank", prompt: trimmed, key: KeychainStore.get("local-provider-token"))
            }
        } catch {
            return demoReply(trimmed, note: "provider connection failed: \(error.localizedDescription)")
        }
    }

    private func request(baseURL: String, model: String, prompt: String, key: String?) async throws -> String {
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: trimmedURL + "/chat/completions"),
              let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            throw ProviderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(
            CompletionRequest(
                model: model,
                messages: [
                    .init(role: "system", content: "you are a helpful coding assistant inside Vibe To App: Refreshed. be honest about capabilities. do not claim files were created or tests were run unless tools actually did that."),
                    .init(role: "user", content: prompt)
                ],
                temperature: 0.7,
                max_tokens: 700
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ProviderError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let apiError = try? JSONDecoder().decode(CompletionResponse.self, from: data)
            throw ProviderError.server(apiError?.error?.message ?? "http \(http.statusCode)")
        }
        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw ProviderError.emptyResponse
        }
        return content
    }

    private func demoReply(_ prompt: String, note: String) -> String {
        """
        **idea received** ✨

        \(prompt)

        **build plan**
        1. define the first screen and core interaction
        2. create a small, testable first version
        3. review proposed file changes before applying them
        4. run checks and iterate

        **provider status:** \(note). this is a planning fallback, not generated project code. no files were changed.
        """
    }
}

private enum ProviderError: LocalizedError {
    case invalidURL, invalidResponse, emptyResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "check the provider base URL"
        case .invalidResponse: return "the provider returned an invalid response"
        case .emptyResponse: return "the provider returned an empty answer"
        case .server(let message): return message
        }
    }
}
