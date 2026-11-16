/// What the person is doing. The bottom controls change to match.
enum ComposerMode: Equatable {
    /// Writing and editing: the full toolbar.
    case normal
    /// Dictating a prompt for the AI: just the Ask button.
    case prompt
    /// Researching a link: just the link field.
    case research
}
