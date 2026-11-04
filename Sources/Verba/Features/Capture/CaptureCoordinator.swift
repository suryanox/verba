import Foundation

@MainActor
final class CaptureCoordinator {
    private let session: VerbaSession
    private let recorder: AudioRecorder
    private let transcriber: Transcriber
    private var originalText: String?
    private var target: FocusedTextTarget?

    var onRecordingStarted: ((FocusedTextTarget, Date) -> Void)?
    var onTranscribing: (() -> Void)?
    var onTranscript: ((String, FocusedTextTarget) -> Void)?
    var onError: ((Error) -> Void)?

    init(
        session: VerbaSession,
        recorder: AudioRecorder,
        transcriber: Transcriber
    ) {
        self.session = session
        self.recorder = recorder
        self.transcriber = transcriber
    }

    func toggle(for target: FocusedTextTarget) {
        self.target = target
        toggle(originalText: target.selectedText)
    }

    func toggle(originalText: String? = nil) {
        switch session.state {
        case .idle:
            start(originalText: originalText)
        case .listening:
            stopAndTranscribe()
        default:
            break
        }
    }

    private func start(originalText: String?) {
        do {
            try recorder.start()
            self.originalText = originalText
            session.startListening()
            if case let .listening(startedAt) = session.state, let target {
                onRecordingStarted?(target, startedAt)
            }
        } catch {
            print("Verba: recording failed: \(error)")
            onError?(error)
        }
    }

    func stop() {
        guard case .listening = session.state else { return }
        stopAndTranscribe()
    }

    private func stopAndTranscribe() {
        do {
            let audioURL = try recorder.stop()
            session.stopListening()
            onTranscribing?()
            Task { [weak self] in
                guard let self else { return }
                do {
                    let transcript = try await transcriber.transcribe(audio: audioURL)
                    session.showTranscript(transcript, replacing: originalText)
                    if let target {
                        onTranscript?(transcript, target)
                    }
                } catch {
                    print("Verba: transcription failed: \(error)")
                    session.cancel()
                    onError?(error)
                }
            }
        } catch {
            print("Verba: stopping recording failed: \(error)")
            session.cancel()
            onError?(error)
        }
    }
}
