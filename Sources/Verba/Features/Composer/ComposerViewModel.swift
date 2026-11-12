import AppKit
import Foundation

enum ComposerPhase: Equatable {
    case ready
    case recording(startedAt: Date)
    case enhancing(WritingAction)
    case error(String)
}

/// A saved snapshot of the document that can be restored from the History popover.
struct DocumentVersion: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let label: String
    let text: String
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
    /// Newest first.
    @Published private(set) var history: [DocumentVersion] = []
    /// When on, dictation is sent to the on-device AI as an instruction instead of being typed into the document.
    @Published var isPromptMode = false
    /// The prompt being dictated, or answered, in prompt mode.
    @Published private(set) var promptText = ""
    /// What the link explainer is doing right now, like "Reading the page…".
    @Published private(set) var linkStatus = ""
    /// True when the current error is about speech permissions, so the banner can offer to open Settings.
    @Published private(set) var errorOpensSettings = false

    private let liveSpeech: LiveSpeechSession
    private let writingAssistant: WritingAssistant
    private let articleFetcher: any ArticleFetching
    private let store: ComposerStore
    private var baseText = ""
    private var recordingGeneration = 0
    private var draftTask: Task<Void, Never>?
    private var snapshotTask: Task<Void, Never>?

    init(
        liveSpeech: LiveSpeechSession = SpeechLiveSession(),
        writingAssistant: WritingAssistant? = nil,
        articleFetcher: any ArticleFetching = URLSessionArticleFetcher(),
        defaults: UserDefaults = .standard
    ) {
        self.liveSpeech = liveSpeech
        self.writingAssistant = writingAssistant ?? Self.makeWritingAssistant()
        self.articleFetcher = articleFetcher
        store = ComposerStore(defaults: defaults)
        text = store.loadText()
        title = store.loadTitle()
        history = store.loadHistory()
    }

    // MARK: - State

    var isRecording: Bool {
        if case .recording = phase {
            return true
        }
        return false
    }

    var isBusy: Bool {
        switch phase {
        case .enhancing: true
        default: false
        }
    }

    var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canRestoreHistory: Bool {
        !isRecording && !isBusy
    }

    var isPromptActive: Bool {
        (isPromptMode && isRecording) || phase == .enhancing(.answerPrompt)
    }

    var isLinkActive: Bool {
        phase == .enhancing(.explainArticle)
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
        let isPrompt = isPromptMode
        if isPrompt {
            promptText = ""
        } else {
            saveVersion("Before dictation")
            baseText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        phase = .recording(startedAt: .now)
        hasCopied = false
        Task { [weak self] in
            guard let self else { return }
            do {
                let partialTexts = try await liveSpeech.start()
                for await partialText in partialTexts {
                    guard recordingGeneration == generation, isRecording else { return }
                    receive(partialText, isPrompt: isPrompt)
                }
                guard recordingGeneration == generation, isRecording else {
                    liveSpeech.stop()
                    return
                }
            } catch {
                guard recordingGeneration == generation else { return }
                fail(error, opensSettings: true)
            }
        }
    }

    /// Routes live speech to the prompt card in prompt mode, or into the document otherwise.
    private func receive(_ partialText: String, isPrompt: Bool) {
        if isPrompt {
            promptText = partialText
        } else {
            let separator = baseText.isEmpty ? "" : " "
            text = baseText + separator + partialText
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        recordingGeneration += 1
        liveSpeech.stop()
        baseText = ""
        phase = .ready

        if isPromptMode {
            sendPrompt(promptText.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            saveVersion("Dictation")
        }
    }

    /// Stops listening in prompt mode without sending anything to the AI.
    func cancelPrompt() {
        guard isRecording else { return }

        recordingGeneration += 1
        liveSpeech.stop()
        promptText = ""
        phase = .ready
    }

    // MARK: - Writing tools

    func apply(_ action: WritingAction) {
        guard hasContent, !isBusy, !isRecording else { return }
        let original = text
        saveVersion("Before \(Self.name(of: action))")
        phase = .enhancing(action)
        Task { [weak self] in
            guard let self else { return }
            do {
                text = try await writingAssistant.transform(original, using: action)
                phase = .ready
                saveVersion(Self.name(of: action).capitalized)
            } catch {
                fail(error)
            }
        }
    }

    /// Sends a dictated prompt to the AI and appends its answer below the existing text.
    private func sendPrompt(_ prompt: String) {
        guard !prompt.isEmpty else {
            promptText = ""
            return
        }
        saveVersion("Before prompt")
        phase = .enhancing(.answerPrompt)
        Task { [weak self] in
            guard let self else { return }
            do {
                append(try await writingAssistant.transform(prompt, using: .answerPrompt))
                promptText = ""
                phase = .ready
                saveVersion("Prompt")
            } catch {
                promptText = ""
                fail(error)
            }
        }
    }

    /// Reads an article and adds a plain-language explanation of it below the existing text.
    func explainLink(_ input: String) {
        guard !isBusy, !isRecording else { return }
        guard let url = ArticleURL.parse(input) else {
            fail(ArticleError.invalidURL)
            return
        }
        saveVersion("Before link explanation")
        phase = .enhancing(.explainArticle)
        Task { [weak self] in
            guard let self else { return }
            let explainer = ArticleExplainer(fetcher: articleFetcher, assistant: writingAssistant)
            do {
                let result = try await explainer.explain(url) { [weak self] status in
                    self?.linkStatus = status
                }
                append(result.formatted)
                phase = .ready
                saveVersion("Link explanation")
            } catch {
                fail(error)
            }
            linkStatus = ""
        }
    }

    private func append(_ block: String) {
        let existing = text.trimmingCharacters(in: .whitespacesAndNewlines)
        text = existing.isEmpty ? block : existing + "\n\n" + block
    }

    private func fail(_ error: Error, opensSettings: Bool = false) {
        errorOpensSettings = opensSettings
        phase = .error(error.localizedDescription)
    }

    private static func name(of action: WritingAction) -> String {
        switch action {
        case .improveGrammar: "grammar fix"
        case .professionalize: "polish"
        case .makeConcise: "shorten"
        case let .changeTone(tone): "\(tone.lowercased()) tone"
        case .answerPrompt: "prompt"
        case .condenseNotes: "notes"
        case .explainArticle: "link explanation"
        }
    }

    // MARK: - History

    /// Stores a snapshot unless it is empty or identical to the newest one.
    func saveVersion(_ label: String) {
        guard hasContent, history.first?.text != text else { return }
        let version = DocumentVersion(id: UUID(), date: .now, label: label, text: text)
        history.insert(version, at: 0)
        if history.count > ComposerStore.historyLimit {
            history.removeLast(history.count - ComposerStore.historyLimit)
        }
        store.saveHistory(history)
    }

    func restore(_ version: DocumentVersion) {
        guard canRestoreHistory else { return }
        saveVersion("Before restore")
        text = version.text
    }

    func deleteVersion(_ version: DocumentVersion) {
        history.removeAll { $0.id == version.id }
        store.saveHistory(history)
    }

    func clearHistory() {
        history = []
        store.saveHistory(history)
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
        saveVersion("Before clear")
        text = ""
        liveSpeech.stop()
        baseText = ""
        phase = .ready
        hasCopied = false
    }

    func exportDocument() {
        do {
            try DocumentExporter.export(text: text, title: title)
        } catch {
            fail(error)
        }
    }

    // MARK: - Errors and settings

    func dismissError() {
        if case .error = phase {
            phase = .ready
        }
    }

    func openSpeechSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Persistence

    /// Writes the draft and a final snapshot immediately. Call this before the app quits.
    func flushDraft() {
        draftTask?.cancel()
        snapshotTask?.cancel()
        store.saveDraft(text: text, title: title)
        saveVersion("Autosave")
    }

    private func scheduleDraftSave() {
        draftTask?.cancel()
        draftTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled, let self else { return }
            store.saveDraft(text: text, title: title)
        }

        // After a pause in typing, keep a snapshot so there is always something to go back to.
        snapshotTask?.cancel()
        snapshotTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled, let self, !isRecording, !isBusy else { return }
            saveVersion("Autosave")
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
