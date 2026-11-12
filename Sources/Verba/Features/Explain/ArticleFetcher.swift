import Foundation

enum ArticleError: Error, Equatable, LocalizedError {
    case invalidURL
    case badStatus(Int)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "That doesn't look like a web link. Paste a full address like https://example.com/article."
        case let .badStatus(code):
            "The site answered with an error (\(code)). It may block automated reading or need a login."
        case .unreadable:
            "I couldn't find readable article text on that page. It may need JavaScript, a login, or a subscription."
        }
    }
}

protocol ArticleFetching: Sendable {
    func html(from url: URL) async throws -> String
}

struct URLSessionArticleFetcher: ArticleFetching {
    private static let maxBytes = 3_000_000
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 "
        + "(KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    func html(from url: URL) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ArticleError.badStatus(http.statusCode)
        }

        let body = data.prefix(Self.maxBytes)
        return String(data: body, encoding: .utf8) ?? String(decoding: body, as: UTF8.self)
    }
}
