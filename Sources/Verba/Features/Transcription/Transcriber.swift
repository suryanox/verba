import Foundation

protocol Transcriber: Sendable {
    func transcribe(audio: URL) async throws -> String
}
