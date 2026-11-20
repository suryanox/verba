import Foundation
import Testing
@testable import Verba

private let structuredReply = """
About: Scientists taught a computer to spot tumors in scans, like teaching a child to tell cats from dogs.
How:
- They collected 10,000 labeled scans.
- They trained a model to match scans to labels.
- They tested it on scans it had never seen.
Results:
- It found 94% of tumors.
- It missed fewer cases than doctors alone.
Diagram: Collect scans > Train model > Test on new scans
"""

// MARK: - Parsing

@Test("A well-formed reply is read into its sections")
func lessonIsParsed() throws {
    let lesson = try #require(ArticleLesson.parse(structuredReply))

    #expect(lesson.about.hasPrefix("Scientists taught a computer"))
    #expect(lesson.how.count == 3)
    #expect(lesson.how.first == "They collected 10,000 labeled scans.")
    #expect(lesson.results == ["It found 94% of tumors.", "It missed fewer cases than doctors alone."])
    #expect(lesson.diagram == ["Collect scans", "Train model", "Test on new scans"])
}

@Test("Bold labels, numbered steps, and different arrows are all accepted")
func lessonToleratesMarkdown() throws {
    let reply = """
    **About:** A new way to store energy.
    **How:**
    1. A step
    2. Next step
    **Results:**
    * Result one
    **Diagram:** One -> Two → Three
    """
    let lesson = try #require(ArticleLesson.parse(reply))

    #expect(lesson.about == "A new way to store energy.")
    #expect(lesson.how == ["A step", "Next step"])
    #expect(lesson.results == ["Result one"])
    #expect(lesson.diagram == ["One", "Two", "Three"])
}

@Test("Parts the article doesn't state are left out, then shown as Not stated")
func notStatedIsHandled() throws {
    let reply = """
    About: A study of sleep.
    How:
    - They asked people about their sleep.
    Results: Not stated.
    """
    let lesson = try #require(ArticleLesson.parse(reply))

    #expect(lesson.results.isEmpty)
    #expect(lesson.formatted().contains("What they found\nNot stated."))
}

@Test("Without a Diagram line, the steps are shortened into one")
func diagramFallsBackToSteps() throws {
    let reply = """
    About: A study.
    How:
    - Collect thousands of patient records carefully
    - Train a model
    Results:
    - It worked.
    """
    let lesson = try #require(ArticleLesson.parse(reply))

    #expect(lesson.diagram == ["Collect thousands of patient", "Train a model"])
}

@Test("Replies that ignore the format are not forced into it")
func unstructuredReplyIsRejected() {
    #expect(ArticleLesson.parse("The idea: networks move data.") == nil)
    #expect(ArticleLesson.parse("About: Only an intro, nothing else.") == nil)
    #expect(ArticleLesson.parse("") == nil)
}

// MARK: - Writing it out

@Test("The document text follows the same three headings every time")
func lessonIsFormatted() throws {
    let text = try #require(ArticleLesson.parse(structuredReply)).formatted()

    #expect(text.hasPrefix("What it's about\nScientists taught a computer"))
    #expect(text.contains("How they did it\n1. They collected 10,000 labeled scans."))
    #expect(text.contains("3. They tested it on scans it had never seen."))
    #expect(text.contains("What they found\n- It found 94% of tumors."))
    #expect(text.contains("In a picture\nCollect scans  →  Train model  →  Test on new scans"))
}

@Test("A diagram too wide for one line is stacked with arrows")
func longDiagramIsStacked() {
    let lesson = ArticleLesson(
        about: "x",
        how: ["a", "b"],
        results: [],
        diagram: ["A fairly long first step name", "A fairly long second step", "Another long third step"]
    )

    #expect(lesson.diagramText.contains("\n↓\n"))
}

// MARK: - End to end

private struct LessonFetcher: ArticleFetching {
    func html(from url: URL) async throws -> String {
        let body = (1...8)
            .map { "<p>Paragraph \($0) explains how researchers scanned patients and trained a model on them.</p>" }
            .joined(separator: "\n")
        return "<html><head><title>Tumor study</title></head><body><article>\(body)</article></body></html>"
    }
}

@MainActor
private struct LessonAssistant: WritingAssistant {
    let reply: String

    func transform(_ text: String, using action: WritingAction) async throws -> String {
        action == .explainArticle ? reply : "- a note"
    }
}

@MainActor
private final class LessonSpeech: LiveSpeechSession {
    func start() async throws -> AsyncStream<String> {
        AsyncStream { continuation in continuation.finish() }
    }

    func stop() {}
}

@MainActor
private func makeLessonModel(reply: String) throws -> ComposerViewModel {
    let suiteName = "verba.tests.lesson.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return ComposerViewModel(
        liveSpeech: LessonSpeech(),
        writingAssistant: LessonAssistant(reply: reply),
        articleFetcher: LessonFetcher(),
        defaults: defaults
    )
}

@MainActor
private func waitUntilIdle(_ model: ComposerViewModel) async {
    for _ in 0..<200 where model.isBusy {
        try? await Task.sleep(for: .milliseconds(10))
    }
}

@Test("Explaining a link writes the structured lesson and sets the diagram")
@MainActor
func explainWritesLessonAndDiagram() async throws {
    let model = try makeLessonModel(reply: structuredReply)

    model.explainLink("https://example.com/tumors")
    await waitUntilIdle(model)

    #expect(model.text.contains("Tumor study\nhttps://example.com/tumors"))
    #expect(model.text.contains("How they did it"))
    #expect(model.text.contains("What they found"))
    #expect(model.diagram == ["Collect scans", "Train model", "Test on new scans"])

    model.dismissDiagram()
    #expect(model.diagram.isEmpty)
}

@Test("If the model ignores the format, its reply is kept as plain text with no diagram")
@MainActor
func explainFallsBackToPlainText() async throws {
    let model = try makeLessonModel(reply: "Networks move data in small packets.")

    model.explainLink("https://example.com/tumors")
    await waitUntilIdle(model)

    #expect(model.text.hasSuffix("Networks move data in small packets."))
    #expect(model.diagram.isEmpty)
}

@Test("The explanation prompt asks for the fixed format and forbids guessing")
func strictPromptFormat() {
    let prompt = WritingPromptBuilder().prompt(for: .explainArticle, text: "Some article")

    #expect(prompt.contains("About:"))
    #expect(prompt.contains("How:"))
    #expect(prompt.contains("Results:"))
    #expect(prompt.contains("Diagram:"))
    #expect(prompt.contains("Not stated."))
    #expect(prompt.contains("Never invent details"))
}
