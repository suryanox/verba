import Foundation

@MainActor
final class UnavailableWritingAssistant: WritingAssistant {
    func transform(_ text: String, using action: WritingAction) async throws -> String {
        throw WritingAssistantError.unavailable
    }
}

enum WritingAssistantError: Error, Equatable {
    case unavailable
}
