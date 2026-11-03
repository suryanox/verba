import Foundation

@MainActor
final class AppCoordinator {
    let session: VerbaSession
    let activation: ActivationCoordinator
    let capture: CaptureCoordinator
    let overlay: OverlayCoordinator
    let textInserter: TextInserter
    private var activeTarget: FocusedTextTarget?

    init(
        session: VerbaSession = VerbaSession(),
        activation: ActivationCoordinator = ActivationCoordinator(),
        recorder: AudioRecorder = AVAudioRecorderService(),
        transcriber: Transcriber = SpeechTranscriber(),
        overlay: OverlayCoordinator = OverlayCoordinator(),
        textInserter: TextInserter = AccessibilityTextInserter()
    ) {
        self.session = session
        self.activation = activation
        self.overlay = overlay
        self.textInserter = textInserter
        capture = CaptureCoordinator(
            session: session,
            recorder: recorder,
            transcriber: transcriber
        )
        activation.onTargetActivated = { [weak self] target in
            self?.activeTarget = target
            self?.capture.toggle(for: target)
        }
        capture.onRecordingStarted = { [weak self] target, startedAt in
            self?.overlay.showRecording(near: target.frame, startedAt: startedAt)
        }
        capture.onTranscribing = { [weak self] in
            self?.overlay.showTranscribing()
        }
        capture.onTranscript = { [weak self] transcript, target in
            self?.overlay.showReview(transcript: transcript, near: target.frame)
        }
        overlay.model.onStop = { [weak self] in
            self?.capture.stop()
        }
        overlay.model.onInsert = { [weak self] text in
            self?.insert(text)
        }
    }

    func start() {
        activation.start()
    }

    func stop() {
        activation.stop()
        overlay.hide()
    }

    private func insert(_ text: String) {
        guard let activeTarget else { return }
        do {
            session.beginInsertion()
            try textInserter.insert(text, into: activeTarget)
            session.finish()
            overlay.hide()
        } catch {
            session.cancel()
        }
    }
}
