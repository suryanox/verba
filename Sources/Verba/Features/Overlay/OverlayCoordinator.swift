import Foundation

@MainActor
final class OverlayCoordinator {
    let model: OverlayViewModel
    private let window: OverlayWindowController

    init(model: OverlayViewModel = OverlayViewModel()) {
        self.model = model
        window = OverlayWindowController(model: model)
    }

    func showRecording(near frame: CGRect?, startedAt: Date) {
        model.showRecording(startedAt: startedAt)
        window.show(near: frame)
    }

    func showTranscribing() {
        model.showTranscribing()
    }

    func showReview(transcript: String, near frame: CGRect?) {
        model.showReview(transcript: transcript)
        window.show(near: frame)
    }

    func hide() {
        model.hide()
        window.hide()
    }
}
