import Foundation
import SwiftUI

enum OverlayPresentation {
    case recording(startedAt: Date)
    case transcribing
    case reviewing(transcript: String)
}

@MainActor
final class OverlayViewModel: ObservableObject {
    @Published private(set) var presentation: OverlayPresentation?

    var onStop: (() -> Void)?
    var onInsert: ((String) -> Void)?

    func showRecording(startedAt: Date) {
        presentation = .recording(startedAt: startedAt)
    }

    func showTranscribing() {
        presentation = .transcribing
    }

    func showReview(transcript: String) {
        presentation = .reviewing(transcript: transcript)
    }

    func hide() {
        presentation = nil
    }
}
