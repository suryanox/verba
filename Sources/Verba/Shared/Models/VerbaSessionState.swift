import Foundation

enum VerbaSessionState: Equatable, Sendable {
    case idle
    case listening(startedAt: Date)
    case transcribing
    case reviewing(originalText: String?, transcript: String)
    case inserting
}
