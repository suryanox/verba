import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26.0, *)
@MainActor
final class FoundationModelsWritingAssistant: WritingAssistant {
    private let promptBuilder = WritingPromptBuilder()

    func transform(_ text: String, using action: WritingAction) async throws -> String {
        let session = LanguageModelSession()
        let response = try await session.respond(
            to: promptBuilder.prompt(for: action, text: text)
        )
        return response.content
    }
}
#endif
