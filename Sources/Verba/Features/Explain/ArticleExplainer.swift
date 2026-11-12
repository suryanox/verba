import Foundation

struct ArticleExplanation: Equatable {
    let title: String
    let url: URL
    let text: String

    /// What gets added to the document: the title, the link, then the lesson.
    var formatted: String {
        let heading = title.isEmpty ? (url.host ?? url.absoluteString) : title
        return "\(heading)\n\(url.absoluteString)\n\n\(text)"
    }
}

enum ArticleURL {
    /// Turns what someone pasted into a web address, or nil when it isn't one.
    static func parse(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else { return nil }

        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host,
              host.contains(".") else { return nil }
        return url
    }
}

/// Splits long text into pieces small enough for the on-device model, breaking on paragraphs when it can.
enum ArticleChunker {
    static func chunks(from text: String, maxCharacters: Int) -> [String] {
        var chunks: [String] = []
        var current = ""

        for paragraph in text.components(separatedBy: "\n\n") {
            for piece in pieces(of: paragraph, maxCharacters: maxCharacters) {
                if !current.isEmpty, current.count + piece.count + 2 > maxCharacters {
                    chunks.append(current)
                    current = ""
                }
                current += current.isEmpty ? piece : "\n\n" + piece
            }
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks
    }

    private static func pieces(of paragraph: String, maxCharacters: Int) -> [String] {
        guard !paragraph.isEmpty else { return [] }
        var pieces: [String] = []
        var remaining = Substring(paragraph)

        while remaining.count > maxCharacters {
            let cut = remaining.index(remaining.startIndex, offsetBy: maxCharacters)
            pieces.append(String(remaining[..<cut]))
            remaining = remaining[cut...]
        }
        pieces.append(String(remaining))
        return pieces
    }
}

/// Fetches an article and explains it like a teacher would.
///
/// Short articles go to the model in one go. Long ones are first boiled down part by part into notes,
/// because the on-device model can only read a few thousand words at a time.
@MainActor
struct ArticleExplainer {
    static let chunkCharacters = 5_000
    static let maxChunks = 8
    static let minimumCharacters = 400

    let fetcher: any ArticleFetching
    let assistant: any WritingAssistant

    func explain(_ url: URL, progress: (String) -> Void = { _ in }) async throws -> ArticleExplanation {
        progress("Reading the page…")
        let html = try await fetcher.html(from: url)
        let article = ArticleExtractor().extract(from: html)
        guard article.text.count >= Self.minimumCharacters else { throw ArticleError.unreadable }

        let material = try await material(from: article.text, progress: progress)
        progress("Writing the explanation…")

        let lesson = try await assistant.transform("Title: \(article.title)\n\n\(material)", using: .explainArticle)
        return ArticleExplanation(
            title: article.title,
            url: url,
            text: lesson.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func material(from text: String, progress: (String) -> Void) async throws -> String {
        let chunks = ArticleChunker.chunks(from: text, maxCharacters: Self.chunkCharacters)
        guard chunks.count > 1 else { return text }

        let used = chunks.prefix(Self.maxChunks)
        var notes: [String] = []
        for (index, chunk) in used.enumerated() {
            progress("Understanding part \(index + 1) of \(used.count)…")
            notes.append(try await assistant.transform(chunk, using: .condenseNotes))
        }
        return String(notes.joined(separator: "\n\n").prefix(Self.chunkCharacters))
    }
}
