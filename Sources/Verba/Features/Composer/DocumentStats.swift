extension String {
    /// Words separated by spaces or line breaks.
    var wordCount: Int {
        split { $0.isWhitespace || $0.isNewline }.count
    }

    /// Estimated reading time at about 230 words a minute, never less than a minute.
    var readingMinutes: Int {
        max(1, Int((Double(wordCount) / 230).rounded(.up)))
    }
}
