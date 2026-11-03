import Foundation

@MainActor
protocol Transcriber {
    func transcribe(audio: URL) async throws -> String
}
