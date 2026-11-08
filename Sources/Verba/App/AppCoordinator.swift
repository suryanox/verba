import Foundation

@MainActor
final class AppCoordinator {
    let session: VerbaSession
    let activation: ActivationCoordinator
    let capture: CaptureCoordinator
    let overlay: OverlayCoordinator
    let textInserter: TextInserter
    let writingAssistant: WritingAssistant
    private var activeTarget: FocusedTextTarget?
    private var reviewedText: String?

    init(
        session: VerbaSession = VerbaSession(),
        activation: ActivationCoordinator = ActivationCoordinator(),
        recorder: AudioRecorder = AVAudioRecorderService(),
        transcriber: Transcriber = SpeechTranscriber(),
        overlay: OverlayCoordinator = OverlayCoordinator(),
        textInserter: TextInserter = AccessibilityTextInserter(),
        writingAssistant: WritingAssistant = AppCoordinator.makeWritingAssistant()
    ) {
        self.session = session
        self.activation = activation
        self.overlay = overlay
        self.textInserter = textInserter
        self.writingAssistant = writingAssistant
        capture = CaptureCoordinator(
            session: session,
            recorder: recorder,
            transcriber: transcriber
        )
        activation.onTargetActivated = { [weak self] target in
            self?.activeTarget = target
            self?.capture.toggle(for: target)
        }
        activation.onActivationFailure = { [weak self] message in
            self?.overlay.showError(message, near: nil)
        }
        capture.onRecordingStarted = { [weak self] target, startedAt in
            self?.overlay.showRecording(near: target.frame, startedAt: startedAt)
        }
        capture.onTranscribing = { [weak self] in
            self?.overlay.showTranscribing()
        }
        capture.onTranscript = { [weak self] transcript, target in
            self?.reviewedText = transcript
            self?.overlay.showReview(transcript: transcript, near: target.frame)
        }
        capture.onError = { [weak self] error in
            guard let self else { return }
            self.overlay.showError(error.localizedDescription, near: activeTarget?.frame)
        }
        overlay.model.onStop = { [weak self] in
            self?.capture.stop()
        }
        overlay.model.onInsert = { [weak self] text in
            self?.insert(text)
        }
        overlay.model.onWritingAction = { [weak self] action in
            self?.transformReviewedText(using: action)
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

    private func transformReviewedText(using action: WritingAction) {
        guard let reviewedText else { return }
        overlay.showTranscribing()
        Task { [weak self] in
            guard let self else { return }
            do {
                let transformed = try await writingAssistant.transform(reviewedText, using: action)
                self.reviewedText = transformed
                overlay.showReview(transcript: transformed, near: activeTarget?.frame)
            } catch {
                overlay.showReview(transcript: reviewedText, near: activeTarget?.frame)
            }
        }
    }

    private static func makeWritingAssistant() -> WritingAssistant {
        if #available(macOS 26.0, *) {
            #if canImport(FoundationModels)
                return FoundationModelsWritingAssistant()
            #else
                return UnavailableWritingAssistant()
            #endif
        }
        return UnavailableWritingAssistant()
    }
}
