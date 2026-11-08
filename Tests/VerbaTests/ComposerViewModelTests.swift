import Foundation
import Testing
@testable import Verba

@MainActor
private final class SpeechStub: LiveSpeechSession {
    func start() async throws -> AsyncStream<String> {
        AsyncStream { continuation in continuation.finish() }
    }

    func stop() {}
}

@MainActor
private struct UppercasingAssistant: WritingAssistant {
    func transform(_ text: String, using _: WritingAction) async throws -> String {
        text.uppercased()
    }
}

@MainActor
private func makeDefaults() throws -> UserDefaults {
    let suiteName = "verba.tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

@MainActor
private func makeModel(defaults: UserDefaults) -> ComposerViewModel {
    ComposerViewModel(
        liveSpeech: SpeechStub(),
        writingAssistant: UppercasingAssistant(),
        defaults: defaults
    )
}

@Test("History skips empty and duplicate snapshots")
@MainActor
func historySkipsEmptyAndDuplicates() throws {
    let model = try makeModel(defaults: makeDefaults())

    model.saveVersion("Empty")
    #expect(model.history.isEmpty)

    model.text = "Hello"
    model.saveVersion("First")
    model.saveVersion("Duplicate")

    #expect(model.history.count == 1)
    #expect(model.history.first?.label == "First")
}

@Test("Restoring a version brings the text back and keeps the current text in history")
@MainActor
func restoreKeepsCurrentText() throws {
    let model = try makeModel(defaults: makeDefaults())

    model.text = "One"
    model.saveVersion("One")
    model.text = "Two"

    let first = try #require(model.history.first)
    model.restore(first)

    #expect(model.text == "One")
    #expect(model.history.map(\.text) == ["Two", "One"])
}

@Test("Clearing the document keeps a restorable copy")
@MainActor
func clearKeepsRestorableCopy() throws {
    let model = try makeModel(defaults: makeDefaults())

    model.text = "Keep me"
    model.clear()

    #expect(model.text.isEmpty)
    #expect(model.history.first?.text == "Keep me")
}

@Test("A writing action saves the text before and after the change")
@MainActor
func writingActionSavesSnapshots() async throws {
    let model = try makeModel(defaults: makeDefaults())

    model.text = "hello"
    model.apply(.improveGrammar)
    for _ in 0 ..< 100 where model.isBusy {
        try? await Task.sleep(for: .milliseconds(10))
    }

    #expect(model.text == "HELLO")
    #expect(model.history.map(\.text) == ["HELLO", "hello"])
}

@Test("Drafts and history survive a relaunch")
@MainActor
func draftAndHistorySurviveRelaunch() throws {
    let defaults = try makeDefaults()

    let first = makeModel(defaults: defaults)
    first.title = "Notes"
    first.text = "Draft"
    first.flushDraft()

    let second = makeModel(defaults: defaults)
    #expect(second.title == "Notes")
    #expect(second.text == "Draft")
    #expect(second.history.first?.text == "Draft")
}
