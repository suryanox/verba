import Foundation

@MainActor
final class CaptureCoordinator {
    private let session: VerbaSession
    private let recorder: AudioRecorder
    private let transcriber: Transcriber
    private var originalText: String?

    var onTranscript: ((String) -> Void)?
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
        } catch {
            onError?(error)
        }
    }

    private func stopAndTranscribe() {
        do {
            let audioURL = try recorder.stop()
            session.stopListening()
            Task { [weak self] in
                guard let self else { return }
                do {
                    let transcript = try await transcriber.transcribe(audio: audioURL)
                    session.showTranscript(transcript, replacing: originalText)
                    onTranscript?(transcript)
                } catch {
                    session.cancel()
                    onError?(error)
                }
            }
        } catch {
            session.cancel()
            onError?(error)
        }
    }
}
