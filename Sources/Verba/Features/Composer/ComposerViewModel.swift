import AppKit
import Foundation

enum ComposerPhase: Equatable {
    case ready
    case recording(startedAt: Date)
    case enhancing(WritingAction)
    case error(String)
}

@MainActor
final class ComposerViewModel: ObservableObject {
    @Published var text = ""
    @Published private(set) var phase: ComposerPhase = .ready
    @Published private(set) var hasCopied = false

    private let liveSpeech: LiveSpeechSession
    private let writingAssistant: WritingAssistant
    private var baseText = ""
    private var recordingGeneration = 0

    init(
        liveSpeech: LiveSpeechSession = SpeechLiveSession(),
        writingAssistant: WritingAssistant? = nil
    ) {
        self.liveSpeech = liveSpeech
        self.writingAssistant = writingAssistant ?? Self.makeWritingAssistant()
    }

    var isRecording: Bool {
        if case .recording = phase { return true }
        return false
    }

    var isBusy: Bool {
        switch phase {
        case .enhancing: return true
        default: return false
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else if !isBusy {
            startRecording()
        }
    }

    func startRecording() {
        recordingGeneration += 1
        let generation = recordingGeneration
        baseText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        phase = .recording(startedAt: .now)
        hasCopied = false
        Task { [weak self] in
            guard let self else { return }
            do {
                let partialTexts = try await liveSpeech.start()
                for await partialText in partialTexts {
                    guard recordingGeneration == generation, isRecording else { return }
                    let separator = baseText.isEmpty ? "" : " "
                    text = baseText + separator + partialText
                }
                guard recordingGeneration == generation, isRecording else {
                    liveSpeech.stop()
                    return
                }
            } catch {
                guard recordingGeneration == generation else { return }
                phase = .error(error.localizedDescription)
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        recordingGeneration += 1
        liveSpeech.stop()
        baseText = ""
        phase = .ready
    }

    func apply(_ action: WritingAction) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isBusy else { return }
        let original = text
        phase = .enhancing(action)
        Task { [weak self] in
            guard let self else { return }
            do {
                text = try await writingAssistant.transform(original, using: action)
                phase = .ready
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    func copyText() {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        hasCopied = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            self?.hasCopied = false
        }
    }

    func clear() {
        recordingGeneration += 1
        text = ""
        liveSpeech.stop()
        baseText = ""
        phase = .ready
        hasCopied = false
    }

    func dismissError() {
        if case .error = phase { phase = .ready }
    }

    func openSpeechSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")
        if let url {
            NSWorkspace.shared.open(url)
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
