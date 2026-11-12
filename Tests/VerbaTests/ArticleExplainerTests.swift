import Foundation
import Testing
@testable import Verba

// MARK: - Fixtures

private func articlePage(paragraphs: Int) -> String {
    let body = (1...paragraphs)
        .map { "<p>Paragraph \($0) explains how packets travel across the internet using routers.</p>" }
        .joined(separator: "\n")

    return """
    <html><head><title>How the Internet Works | Example</title>
    <script>var secret = "ignore this script";</script></head>
    <body>
    <nav><a href="/">Home</a> Menu item that should disappear</nav>
    <article><h1>How the internet works</h1>
    \(body)
    </article>
    <footer>Copyright footer that should disappear</footer>
    </body></html>
    """
}

private struct StubFetcher: ArticleFetching {
    let page: String

    func html(from url: URL) async throws -> String {
        page
    }
}

@MainActor
private final class RecordingAssistant: WritingAssistant {
    private(set) var actions: [WritingAction] = []
    private(set) var inputs: [String] = []

    func transform(_ text: String, using action: WritingAction) async throws -> String {
        actions.append(action)
        inputs.append(text)
        return action == .explainArticle ? "The idea: networks move data." : "- a note"
    }
}

@MainActor
private final class SilentSpeech: LiveSpeechSession {
    func start() async throws -> AsyncStream<String> {
        AsyncStream { continuation in continuation.finish() }
    }

    func stop() {}
}

@MainActor
private func isolatedDefaults() throws -> UserDefaults {
    let suiteName = "verba.tests.article.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

// MARK: - Links

@Test("Pasted links are cleaned up, and non-links are rejected")
func linksAreParsed() {
    #expect(ArticleURL.parse("example.com/post")?.absoluteString == "https://example.com/post")
    #expect(ArticleURL.parse("  https://example.com/a  ")?.host == "example.com")
    #expect(ArticleURL.parse("not a link") == nil)
    #expect(ArticleURL.parse("ftp://example.com/file") == nil)
    #expect(ArticleURL.parse("localhost") == nil)
    #expect(ArticleURL.parse("") == nil)
}

// MARK: - Extraction

@Test("The extractor keeps the article and drops menus, scripts, and footers")
func extractorKeepsTheArticle() {
    let article = ArticleExtractor().extract(from: articlePage(paragraphs: 6))

    #expect(article.title == "How the Internet Works | Example")
    #expect(article.text.contains("# How the internet works"))
    #expect(article.text.contains("Paragraph 1 explains how packets travel"))
    #expect(!article.text.contains("Menu item"))
    #expect(!article.text.contains("ignore this script"))
    #expect(!article.text.contains("footer"))
}

@Test("The extractor decodes HTML entities")
func extractorDecodesEntities() {
    let html = "<p>Tom &amp; Jerry&#39;s &#8220;show&#8221; is long enough to keep around here.</p>"
    let article = ArticleExtractor().extract(from: html)

    #expect(article.text == "Tom & Jerry's “show” is long enough to keep around here.")
}

// MARK: - Chunking

@Test("Short text stays in one piece")
func shortTextIsOneChunk() {
    #expect(ArticleChunker.chunks(from: "A short paragraph.", maxCharacters: 100) == ["A short paragraph."])
}

@Test("Long text is split on paragraphs, and no piece is too big")
func longTextIsSplit() {
    let paragraph = String(repeating: "a", count: 40)
    let text = Array(repeating: paragraph, count: 10).joined(separator: "\n\n")
    let chunks = ArticleChunker.chunks(from: text, maxCharacters: 100)

    #expect(chunks.count == 5)
    #expect(chunks.allSatisfy { $0.count <= 100 })
}

@Test("A single huge paragraph is cut up too")
func hugeParagraphIsCut() {
    let chunks = ArticleChunker.chunks(from: String(repeating: "b", count: 250), maxCharacters: 100)

    #expect(chunks.map(\.count) == [100, 100, 50])
}

// MARK: - Explaining

@MainActor
private func makeExplainer(page: String, assistant: RecordingAssistant) -> ArticleExplainer {
    ArticleExplainer(fetcher: StubFetcher(page: page), assistant: assistant)
}

@Test("A short article is explained in one step")
@MainActor
func shortArticleIsExplainedDirectly() async throws {
    let assistant = RecordingAssistant()
    let explainer = makeExplainer(page: articlePage(paragraphs: 8), assistant: assistant)
    let url = try #require(URL(string: "https://example.com/internet"))

    let result = try await explainer.explain(url)

    #expect(assistant.actions == [.explainArticle])
    #expect(assistant.inputs.first?.contains("Title: How the Internet Works") == true)
    #expect(result.text == "The idea: networks move data.")
    #expect(result.url == url)
}

@Test("A long article is boiled down into notes before it is explained")
@MainActor
func longArticleIsCondensedFirst() async throws {
    let assistant = RecordingAssistant()
    let explainer = makeExplainer(page: articlePage(paragraphs: 80), assistant: assistant)
    let url = try #require(URL(string: "https://example.com/long"))

    _ = try await explainer.explain(url)

    #expect(assistant.actions.count > 2)
    #expect(assistant.actions.last == .explainArticle)
    #expect(assistant.actions.dropLast().allSatisfy { $0 == .condenseNotes })
    #expect(assistant.inputs.last?.contains("- a note") == true)
}

@Test("A page with no readable text is reported, not guessed at")
@MainActor
func unreadablePageIsReported() async throws {
    let page = "<html><body><p>Enable JavaScript.</p></body></html>"
    let explainer = makeExplainer(page: page, assistant: RecordingAssistant())
    let url = try #require(URL(string: "https://example.com/app"))

    do {
        _ = try await explainer.explain(url)
        Issue.record("Expected the page to be reported as unreadable")
    } catch {
        #expect(error as? ArticleError == .unreadable)
    }
}

@Test("The teacher prompt asks for plain, grounded teaching and the notes prompt stays short")
func teacherPromptRules() {
    let builder = WritingPromptBuilder()
    let teacher = builder.prompt(for: .explainArticle, text: "Some article")
    let notes = builder.prompt(for: .condenseNotes, text: "Some part")

    #expect(teacher.contains("old-school teacher"))
    #expect(teacher.contains("complete beginner"))
    #expect(teacher.contains("Never invent details"))
    #expect(teacher.contains("Some article"))
    #expect(notes.contains("at most 8 bullets"))
}

// MARK: - In the app

@Test("Explaining a link adds the title, the link, and the lesson to the document")
@MainActor
func explainLinkAddsLesson() async throws {
    let model = ComposerViewModel(
        liveSpeech: SilentSpeech(),
        writingAssistant: RecordingAssistant(),
        articleFetcher: StubFetcher(page: articlePage(paragraphs: 8)),
        defaults: try isolatedDefaults()
    )
    model.text = "My notes"

    model.explainLink("https://example.com/internet")
    for _ in 0..<200 where model.isBusy {
        try? await Task.sleep(for: .milliseconds(10))
    }

    let expected = "My notes\n\nHow the Internet Works | Example\nhttps://example.com/internet\n\n"
        + "The idea: networks move data."
    #expect(model.text == expected)
    #expect(model.linkStatus.isEmpty)
    #expect(model.history.first?.text == expected)
}

@Test("A pasted non-link shows a clear error and changes nothing")
@MainActor
func invalidLinkShowsError() throws {
    let model = ComposerViewModel(
        liveSpeech: SilentSpeech(),
        writingAssistant: RecordingAssistant(),
        articleFetcher: StubFetcher(page: ""),
        defaults: try isolatedDefaults()
    )
    model.text = "My notes"

    model.explainLink("not a link")

    #expect(model.phase == .error(ArticleError.invalidURL.localizedDescription))
    #expect(!model.errorOpensSettings)
    #expect(model.text == "My notes")
}
