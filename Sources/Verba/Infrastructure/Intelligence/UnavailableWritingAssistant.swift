import Foundation

@MainActor
final class UnavailableWritingAssistant: WritingAssistant {
    func transform(_: String, using _: WritingAction) async throws -> String {
        throw WritingAssistantError.unavailable
    }
}

enum WritingAssistantError: Error, Equatable, LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Writing tools need Apple Intelligence, which isn't available on this Mac."
        }
    }
}
