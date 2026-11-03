import Foundation
import Testing
@testable import Verba

@MainActor
private final class RecordingStub: AudioRecorder {
    private(set) var isRecording = false
    let audioURL = URL(fileURLWithPath: "/tmp/verba-test.m4a")

    func start() throws {
        isRecording = true
    }

    func stop() throws -> URL {
        isRecording = false
        return audioURL
    }
}

@MainActor
private final class TranscriberStub: Transcriber {
    var result = "Transcribed text"
    private(set) var receivedURL: URL?

    func transcribe(audio: URL) async throws -> String {
        receivedURL = audio
        return result
    }
}

@Test("Capture starts recording and moves the session to listening")
@MainActor
func captureStartsRecording() {
    let session = VerbaSession()
    let recorder = RecordingStub()
    let transcriber = TranscriberStub()
    let capture = CaptureCoordinator(
        session: session,
        recorder: recorder,
        transcriber: transcriber
    )

    capture.toggle(originalText: "Existing text")

    #expect(recorder.isRecording)
    #expect(session.state == .listening(startedAt: sessionListeningDate(from: session)))
}

@Test("Capture stops, transcribes, and moves the session to review")
@MainActor
func captureTranscribesRecording() async {
    let session = VerbaSession()
    let recorder = RecordingStub()
    let transcriber = TranscriberStub()
    let capture = CaptureCoordinator(
        session: session,
        recorder: recorder,
        transcriber: transcriber
    )

    capture.toggle()
    capture.toggle()
    await Task.yield()

    #expect(transcriber.receivedURL == recorder.audioURL)
    #expect(session.state == .reviewing(originalText: nil, transcript: "Transcribed text"))
}

@MainActor
private func sessionListeningDate(from session: VerbaSession) -> Date {
    guard case let .listening(startedAt) = session.state else {
        Issue.record("Expected a listening state")
        return .distantPast
    }
    return startedAt
}
