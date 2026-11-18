import Foundation

/// A strict, structured lesson: what it is about, how it was done, what came out of it,
/// and a few short step names that can be drawn as a flow diagram.
struct ArticleLesson: Equatable {
    let about: String
    let how: [String]
    let results: [String]
    /// Short step names in order. Empty when there is nothing worth drawing.
    let diagram: [String]

    private static let notStated = "Not stated."
    private static let maxNodes = 6
    private static let maxLabelLength = 32
    private static let oneLineLimit = 72

    private enum Section: Hashable {
        case about
        case how
        case results
        case diagram
    }

    // MARK: - Parsing

    /// Reads the labeled reply from the model. Returns nil when it didn't follow the format,
    /// so the caller can fall back to showing the reply as plain text.
    static func parse(_ text: String) -> ArticleLesson? {
        var sections: [Section: [String]] = [:]
        var current: Section?

        for rawLine in text.components(separatedBy: .newlines) {
            let line = clean(rawLine)
            guard !line.isEmpty else { continue }

            if let found = header(in: line) {
                current = found.section
                if !found.rest.isEmpty {
                    sections[found.section, default: []].append(found.rest)
                }
            } else if let current {
                sections[current, default: []].append(line)
            }
        }

        let about = (sections[.about] ?? []).joined(separator: " ")
        let how = items(sections[.how] ?? [])
        let results = items(sections[.results] ?? [])
        guard !about.isEmpty, !how.isEmpty || !results.isEmpty else { return nil }

        return ArticleLesson(
            about: about,
            how: how,
            results: results,
            diagram: nodes(from: sections[.diagram] ?? [], fallback: how)
        )
    }

    private static func header(in line: String) -> (section: Section, rest: String)? {
        let lowered = line.lowercased()
        let labels: [(name: String, section: Section)] = [
            ("about", .about), ("how", .how), ("results", .results), ("result", .results), ("diagram", .diagram)
        ]
        for label in labels where lowered.hasPrefix(label.name + ":") {
            let rest = String(line.dropFirst(label.name.count + 1)).trimmingCharacters(in: .whitespaces)
            return (label.section, rest)
        }
        return nil
    }

    /// Removes markdown the model sometimes adds, like **bold** and # headings.
    private static func clean(_ line: String) -> String {
        let plain = line.replacingOccurrences(of: "*", with: "")
        let trimmed = plain.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.drop(while: { $0 == "#" || $0 == " " }))
    }

    private static func stripBullet(_ line: String) -> String {
        var result = line
        if let range = result.range(of: #"^\s*([-•–]|\d+[.)])\s+"#, options: .regularExpression) {
            result.removeSubrange(range)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isNotStated(_ text: String) -> Bool {
        text.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ". ")) == "not stated"
    }

    private static func items(_ lines: [String]) -> [String] {
        lines.map(stripBullet).filter { !$0.isEmpty && !isNotStated($0) }
    }

    // MARK: - Diagram steps

    /// Uses the model's own "Diagram:" line when it gave one. Otherwise it shortens the How steps.
    private static func nodes(from lines: [String], fallback: [String]) -> [String] {
        let joined = lines.joined(separator: " > ").replacingOccurrences(of: "->", with: ">")
        let parts = joined.components(separatedBy: CharacterSet(charactersIn: ">→;"))
        let listed = parts
            .map(stripBullet)
            .filter { !$0.isEmpty && !isNotStated($0) }
            .map(capLabel)

        if listed.count >= 2 {
            return Array(listed.prefix(maxNodes))
        }
        guard fallback.count >= 2 else { return [] }
        return fallback.prefix(maxNodes).map(shortLabel)
    }

    private static func capLabel(_ text: String) -> String {
        let cleaned = text.trimmingCharacters(in: CharacterSet(charactersIn: " .,;:"))
        guard cleaned.count > maxLabelLength else { return cleaned }
        return String(cleaned.prefix(maxLabelLength - 1)) + "…"
    }

    private static func shortLabel(_ text: String) -> String {
        capLabel(text.split(separator: " ").prefix(4).joined(separator: " "))
    }

    // MARK: - Writing it out

    /// The plain-text version that goes into the document.
    func formatted() -> String {
        var lines = ["What it's about", about, "", "How they did it"]
        lines += how.isEmpty ? [Self.notStated] : how.enumerated().map { "\($0.offset + 1). \($0.element)" }
        lines += ["", "What they found"]
        lines += results.isEmpty ? [Self.notStated] : results.map { "- " + $0 }
        if diagram.count >= 2 {
            lines += ["", "In a picture", diagramText]
        }
        return lines.joined(separator: "\n")
    }

    /// A text diagram that survives any font: one line when it fits, otherwise stacked with arrows.
    var diagramText: String {
        let oneLine = diagram.joined(separator: "  →  ")
        return oneLine.count <= Self.oneLineLimit ? oneLine : diagram.joined(separator: "\n↓\n")
    }
}
