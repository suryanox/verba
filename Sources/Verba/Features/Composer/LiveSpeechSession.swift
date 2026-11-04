import Foundation

@MainActor
protocol LiveSpeechSession {
    func start() async throws -> AsyncStream<String>
    func stop()
}
