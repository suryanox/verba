import Foundation

enum WritingAction: Equatable, Sendable {
    case improveGrammar
    case professionalize
    case makeConcise
    case changeTone(String)
    /// Treats the text as an instruction to follow, rather than text to rewrite.
    case answerPrompt
    /// Pulls the key facts out of one part of a long article, as short notes.
    case condenseNotes
    /// Explains an article like a patient teacher talking to a complete beginner.
    case explainArticle
}

@MainActor
protocol WritingAssistant {
    func transform(_ text: String, using action: WritingAction) async throws -> String
}
