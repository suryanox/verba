import Foundation

@MainActor
final class AppCoordinator {
    let session: VerbaSession
    let activation: ActivationCoordinator
    let capture: CaptureCoordinator

    init(
        session: VerbaSession = VerbaSession(),
        activation: ActivationCoordinator = ActivationCoordinator(),
        recorder: AudioRecorder = AVAudioRecorderService(),
        transcriber: Transcriber = SpeechTranscriber()
    ) {
        self.session = session
        self.activation = activation
        capture = CaptureCoordinator(
            session: session,
            recorder: recorder,
            transcriber: transcriber
        )
        activation.onTargetActivated = { [weak self] target in
            self?.capture.toggle(for: target)
        }
    }

    func start() {
        activation.start()
    }

    func stop() {
        activation.stop()
    }
}
