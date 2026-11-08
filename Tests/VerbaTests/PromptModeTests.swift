import Foundation
import Testing
@testable import Verba

@MainActor
private final class ScriptedSpeech: LiveSpeechSession {
    func start() async throws -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.yield("write a haiku")
            continuation.finish()
        }
    }

    func stop() {}
}

@MainActor
private struct EchoAssistant: WritingAssistant {
    func transform(_ text: String, using action: WritingAction) async throws -> String {
        text.uppercased()
    }
}

@MainActor
private func makePromptModel() throws -> ComposerViewModel {
    let suiteName = "verba.tests.prompt.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return ComposerViewModel(liveSpeech: ScriptedSpeech(), writingAssistant: EchoAssistant(), defaults: defaults)
}

@Test("Prompt requests ask the AI to follow the dictated instruction")
func answerPromptWording() {
    let prompt = WritingPromptBuilder().prompt(for: .answerPrompt, text: "write a haiku about rain")

    #expect(prompt.contains("write a haiku about rain"))
    #expect(prompt.contains("dictated by voice"))
    #expect(prompt.contains("only the finished text"))
}

@Test("Prompt mode is off by default")
@MainActor
func promptModeDefaultsOff() throws {
    let model = try makePromptModel()
    #expect(!model.isPromptMode)
}

@Test("A dictated prompt goes to the AI and the answer is appended to the document")
@MainActor
func dictatedPromptIsAnswered() async throws {
    let model = try makePromptModel()
    model.text = "Existing"
    model.isPromptMode = true

    model.startRecording()
    for _ in 0..<100 where model.promptText.isEmpty {
        try? await Task.sleep(for: .milliseconds(10))
    }

    // While speaking, the words go to the prompt card and the document is untouched.
    #expect(model.promptText == "write a haiku")
    #expect(model.text == "Existing")

    model.stopRecording()
    for _ in 0..<100 where model.isBusy {
        try? await Task.sleep(for: .milliseconds(10))
    }

    #expect(model.text == "Existing\n\nWRITE A HAIKU")
    #expect(model.promptText.isEmpty)
}

@Test("Cancelling a prompt sends nothing to the AI")
@MainActor
func cancelledPromptIsDiscarded() async throws {
    let model = try makePromptModel()
    model.text = "Existing"
    model.isPromptMode = true

    model.startRecording()
    for _ in 0..<100 where model.promptText.isEmpty {
        try? await Task.sleep(for: .milliseconds(10))
    }
    model.cancelPrompt()

    #expect(model.text == "Existing")
    #expect(model.promptText.isEmpty)
    #expect(!model.isRecording)
    #expect(!model.isBusy)
}
