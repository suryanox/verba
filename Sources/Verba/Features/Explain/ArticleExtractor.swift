import Foundation

struct ExtractedArticle: Equatable {
    let title: String
    let text: String
}

/// Pulls the readable article out of a web page: the title plus headings, paragraphs, and list items.
/// It is deliberately simple. Pages that build their text with JavaScript will come back nearly empty.
struct ArticleExtractor {
    private static let noiseTags = [
        "script", "style", "noscript", "svg", "nav", "header", "footer", "aside", "form", "iframe", "template"
    ]

    private static let namedEntities = [
        "&nbsp;": " ", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&lt;": "<", "&gt;": ">",
        "&ndash;": "–", "&mdash;": "—", "&hellip;": "…",
        "&lsquo;": "‘", "&rsquo;": "’", "&ldquo;": "“", "&rdquo;": "”"
    ]

    func extract(from html: String) -> ExtractedArticle {
        let cleaned = removeNoise(from: html)
        let region = mainRegion(of: cleaned)
        return ExtractedArticle(title: title(in: html), text: readableText(in: region))
    }

    // MARK: - Steps

    private func removeNoise(from html: String) -> String {
        var result = replace("<!--.*?-->", in: html)
        for tag in Self.noiseTags {
            result = replace("<\(tag)\\b[^>]*>.*?</\(tag)>", in: result)
        }
        return result
    }

    /// Prefers the biggest <article> or <main> block, since that is where the story usually lives.
    private func mainRegion(of html: String) -> String {
        for tag in ["article", "main"] {
            let blocks = captures("<\(tag)\\b[^>]*>(.*?)</\(tag)>", in: html)
            if let best = blocks.max(by: { $0.count < $1.count }), best.count > 800 {
                return best
            }
        }
        return html
    }

    private func title(in html: String) -> String {
        let patterns = [
            "<meta[^>]+property=[\"']og:title[\"'][^>]+content=[\"']([^\"']*)[\"']",
            "<title[^>]*>(.*?)</title>"
        ]
        for pattern in patterns {
            if let first = captures(pattern, in: html).first {
                let cleaned = cleanInline(first)
                if !cleaned.isEmpty { return cleaned }
            }
        }
        return ""
    }

    private func readableText(in html: String) -> String {
        let pattern = "<(h1|h2|h3|h4|p|li|blockquote|pre)\\b[^>]*>(.*?)</\\1>"
        var lines: [String] = []
        var seen = Set<String>()

        for groups in captureGroups(pattern, in: html) where groups.count == 2 {
            let text = cleanInline(groups[1])
            guard !text.isEmpty, seen.insert(text).inserted else { continue }
            switch groups[0].lowercased() {
            case "h1", "h2", "h3", "h4":
                lines.append("# " + text)
            case "li":
                if text.count >= 25 { lines.append("- " + text) }
            default:
                if text.count >= 40 { lines.append(text) }
            }
        }
        return lines.joined(separator: "\n\n")
    }

    // MARK: - Text cleanup

    private func cleanInline(_ html: String) -> String {
        var text = replace("<br\\s*/?>", with: " ", in: html)
        text = replace("<[^>]+>", in: text)
        text = decodeEntities(text)
        text = replace("\\s+", with: " ", in: text)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeEntities(_ text: String) -> String {
        var result = text
        for (entity, value) in Self.namedEntities {
            result = result.replacingOccurrences(of: entity, with: value)
        }
        result = decodeNumericEntities(in: result)
        return result.replacingOccurrences(of: "&amp;", with: "&")
    }

    private func decodeNumericEntities(in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "&#([xX]?)([0-9a-fA-F]+);") else { return text }
        let source = text as NSString
        var result = text
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: source.length))

        // Work backwards so earlier ranges stay valid while we replace.
        for match in matches.reversed() {
            let isHex = !source.substring(with: match.range(at: 1)).isEmpty
            let digits = source.substring(with: match.range(at: 2))
            guard let code = UInt32(digits, radix: isHex ? 16 : 10),
                  let scalar = Unicode.Scalar(code),
                  let range = Range(match.range, in: result) else { continue }
            result.replaceSubrange(range, with: String(Character(scalar)))
        }
        return result
    }

    // MARK: - Regex helpers

    private func makeRegex(_ pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
    }

    private func replace(_ pattern: String, with template: String = "", in text: String) -> String {
        guard let regex = makeRegex(pattern) else { return text }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }

    /// Every match, as the list of its capture groups.
    private func captureGroups(_ pattern: String, in text: String) -> [[String]] {
        guard let regex = makeRegex(pattern) else { return [] }
        let source = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: source.length))

        return matches.map { match in
            (1..<match.numberOfRanges).map { index in
                let range = match.range(at: index)
                return range.location == NSNotFound ? "" : source.substring(with: range)
            }
        }
    }

    /// The first capture group of every match.
    private func captures(_ pattern: String, in text: String) -> [String] {
        captureGroups(pattern, in: text).compactMap(\.first)
    }
}
