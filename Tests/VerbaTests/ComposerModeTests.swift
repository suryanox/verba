import Foundation
import Testing
@testable import Verba

@MainActor
private final class ModeSpeech: LiveSpeechSession {
    func start() async throws -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.yield("write a haiku")
            continuation.finish()
        }
    }

    func stop() {}
}

@MainActor
private struct ModeAssistant: WritingAssistant {
    func transform(_ text: String, using action: WritingAction) async throws -> String {
        action == .explainArticle ? "The idea: networks move data." : text.uppercased()
    }
}

private struct ModeFetcher: ArticleFetching {
    func html(from url: URL) async throws -> String {
        let body = (1...8)
            .map { "<p>Paragraph \($0) explains how packets travel across the internet using routers.</p>" }
            .joined(separator: "\n")
        return "<html><head><title>Packets</title></head><body><article>\(body)</article></body></html>"
    }
}

@MainActor
private func makeModeModel() throws -> ComposerViewModel {
    let suiteName = "verba.tests.mode.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return ComposerViewModel(
        liveSpeech: ModeSpeech(),
        writingAssistant: ModeAssistant(),
        articleFetcher: ModeFetcher(),
        defaults: defaults
    )
}

@MainActor
private func waitUntilIdle(_ model: ComposerViewModel) async {
    for _ in 0..<200 where model.isBusy {
        try? await Task.sleep(for: .milliseconds(10))
    }
}

@Test("The full toolbar is shown by default, and the prompt checkbox maps onto prompt mode")
@MainActor
func modeDefaultsToNormal() throws {
    let model = try makeModeModel()
    #expect(model.mode == .normal)

    model.isPromptMode = true
    #expect(model.mode == .prompt)

    model.isPromptMode = false
    #expect(model.mode == .normal)
}

@Test("Typing or pasting brings back the full toolbar from Ask AI and Explain mode")
@MainActor
func userEditsExitModes() throws {
    let model = try makeModeModel()

    model.mode = .prompt
    model.exitMode()
    #expect(model.mode == .normal)

    model.mode = .explain
    model.exitMode()
    #expect(model.mode == .normal)
}

@Test("The toolbar stays hidden while the microphone is open")
@MainActor
func modeStaysWhileListening() async throws {
    let model = try makeModeModel()
    model.mode = .prompt
    model.startRecording()

    model.exitMode()
    #expect(model.mode == .prompt)

    model.cancelPrompt()
    #expect(model.mode == .prompt)
}

@Test("After a dictated prompt is answered, the full toolbar comes back")
@MainActor
func answeredPromptReturnsToNormal() async throws {
    let model = try makeModeModel()
    model.mode = .prompt

    model.startRecording()
    for _ in 0..<100 where model.promptText.isEmpty {
        try? await Task.sleep(for: .milliseconds(10))
    }
    model.stopRecording()
    await waitUntilIdle(model)

    #expect(model.mode == .normal)
    #expect(model.text == "WRITE A HAIKU")
}

@Test("After a link is explained, the full toolbar comes back")
@MainActor
func explainedLinkReturnsToNormal() async throws {
    let model = try makeModeModel()
    model.mode = .explain

    model.explainLink("https://example.com/packets")
    await waitUntilIdle(model)

    #expect(model.mode == .normal)
    #expect(model.text.contains("The idea: networks move data."))
}

@Test("A bad link keeps Explain mode open so it can be fixed")
@MainActor
func badLinkKeepsExplainMode() throws {
    let model = try makeModeModel()
    model.mode = .explain

    model.explainLink("not a link")

    #expect(model.mode == .explain)
}
