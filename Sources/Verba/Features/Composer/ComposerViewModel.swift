import AppKit
import Foundation

enum ComposerPhase: Equatable {
    case ready
    case recording(startedAt: Date)
    case transcribing
    case enhancing(WritingAction)
    case error(String)
}

@MainActor
final class ComposerViewModel: ObservableObject {
    @Published var text = ""
    @Published private(set) var phase: ComposerPhase = .ready
    @Published private(set) var hasCopied = false

    private let recorder: AudioRecorder
    private let transcriber: Transcriber
    private let writingAssistant: WritingAssistant

    init(
        recorder: AudioRecorder = AVAudioRecorderService(),
        transcriber: Transcriber = SpeechTranscriber(),
        writingAssistant: WritingAssistant? = nil
    ) {
        self.recorder = recorder
        self.transcriber = transcriber
        self.writingAssistant = writingAssistant ?? Self.makeWritingAssistant()
    }

    var isRecording: Bool {
        if case .recording = phase { return true }
        return false
    }

    var isBusy: Bool {
        switch phase {
        case .transcribing, .enhancing: return true
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
        do {
            try recorder.start()
            phase = .recording(startedAt: .now)
            hasCopied = false
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        do {
            let audioURL = try recorder.stop()
            phase = .transcribing
            Task { [weak self] in
                guard let self else { return }
                do {
                    let transcript = try await transcriber.transcribe(audio: audioURL)
                    text = transcript
                    phase = .ready
                } catch {
                    phase = .error(error.localizedDescription)
                }
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
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
        text = ""
        phase = .ready
        hasCopied = false
    }

    func dismissError() {
        if case .error = phase { phase = .ready }
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
