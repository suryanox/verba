import AppKit
import Foundation
import UniformTypeIdentifiers

enum ComposerPhase: Equatable {
    case ready
    case recording(startedAt: Date)
    case enhancing(WritingAction)
    case error(String)
}

@MainActor
final class ComposerViewModel: ObservableObject {
    static let tones = ["Friendly", "Casual", "Confident", "Warm", "Persuasive", "Formal"]

    @Published var text = "" {
        didSet { scheduleDraftSave() }
    }
    @Published var title = "" {
        didSet { scheduleDraftSave() }
    }
    @Published private(set) var phase: ComposerPhase = .ready
    @Published private(set) var hasCopied = false
    /// The text as it was before the last AI edit or clear, so it can be swapped back.
    @Published private(set) var previousText: String?

    private let liveSpeech: LiveSpeechSession
    private let writingAssistant: WritingAssistant
    private let defaults: UserDefaults
    private var baseText = ""
    private var recordingGeneration = 0
    private var draftTask: Task<Void, Never>?

    init(
        liveSpeech: LiveSpeechSession = SpeechLiveSession(),
        writingAssistant: WritingAssistant? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.liveSpeech = liveSpeech
        self.writingAssistant = writingAssistant ?? Self.makeWritingAssistant()
        self.defaults = defaults
        text = defaults.string(forKey: Self.textKey) ?? ""
        title = defaults.string(forKey: Self.titleKey) ?? ""
    }

    // MARK: - State

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

    var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canRevert: Bool {
        previousText != nil && !isRecording && !isBusy
    }

    var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    var readingMinutes: Int {
        max(1, Int((Double(wordCount) / 230).rounded(.up)))
    }

    // MARK: - Dictation

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

    // MARK: - Writing tools

    func apply(_ action: WritingAction) {
        guard hasContent, !isBusy, !isRecording else { return }
        let original = text
        phase = .enhancing(action)
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await writingAssistant.transform(original, using: action)
                previousText = original
                text = result
                phase = .ready
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    /// Swaps the current text with the version saved before the last AI edit or clear.
    func revert() {
        guard let previousText, canRevert else { return }
        let current = text
        text = previousText
        self.previousText = current.isEmpty ? nil : current
    }

    // MARK: - Document

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
        if !text.isEmpty { previousText = text }
        text = ""
        liveSpeech.stop()
        baseText = ""
        phase = .ready
        hasCopied = false
    }

    func exportDocument() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        panel.nameFieldStringValue = (name.isEmpty ? "Untitled" : name) + ".txt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    // MARK: - Errors and settings

    func dismissError() {
        if case .error = phase { phase = .ready }
    }

    func openSpeechSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Draft persistence

    /// Writes the draft immediately. Call this before the app quits.
    func flushDraft() {
        draftTask?.cancel()
        persistDraft()
    }

    private static let textKey = "verba.draft.text"
    private static let titleKey = "verba.draft.title"

    private func scheduleDraftSave() {
        draftTask?.cancel()
        draftTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            self?.persistDraft()
        }
    }

    private func persistDraft() {
        defaults.set(text, forKey: Self.textKey)
        defaults.set(title, forKey: Self.titleKey)
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
