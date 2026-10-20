import Foundation

enum AgentMode: String {
    case cloud, local, hybrid
}

protocol AIProvider {
    func generate(prompt: String) async throws -> String
}

/// The provider boundary keeps UI code independent from any specific model vendor.
/// Credentials and concrete network adapters will be added through secure storage,
/// never as constants in the application bundle.
struct AgentCore {
    func respond(to prompt: String) async -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "give me an idea to work with and we'll get started." }

        // This honest local fallback makes the prototype usable without an API key.
        // It does not pretend to have generated or edited project files yet.
        return """
        **idea received** ✨

        (trimmed)

        **build plan**
        1. clarify the core screen and main interaction
        2. create a small, testable first version
        3. review the file changes before applying them
        4. run checks and iterate

        **prototype status:** i'm running in demo mode right now. no cloud request was sent, and no files have been changed yet. connect a compatible provider in a future build to enable real code generation.
        """
    }
}
