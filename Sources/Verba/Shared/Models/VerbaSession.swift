import Foundation

@MainActor
final class VerbaSession {
    private(set) var state: VerbaSessionState = .idle

    func startListening(at date: Date = .now) {
        guard state == .idle else { return }
        state = .listening(startedAt: date)
    }

    func stopListening() {
        guard case .listening = state else { return }
        state = .transcribing
    }

    func showTranscript(_ transcript: String, replacing originalText: String? = nil) {
        guard case .transcribing = state else { return }
        state = .reviewing(originalText: originalText, transcript: transcript)
    }

    func beginInsertion() {
        guard case .reviewing = state else { return }
        state = .inserting
    }

    func finish() {
        state = .idle
    }

    func cancel() {
        state = .idle
    }
}
