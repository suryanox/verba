import Foundation

@MainActor
protocol AudioRecorder {
    var isRecording: Bool { get }
    func start() throws
    func stop() throws -> URL
}
