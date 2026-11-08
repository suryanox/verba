import Foundation

enum WritingAction: Equatable, Sendable {
    case improveGrammar
    case professionalize
    case makeConcise
    case changeTone(String)
    /// Treats the text as an instruction to follow, rather than text to rewrite.
    case answerPrompt
}

@MainActor
protocol WritingAssistant {
    func transform(_ text: String, using action: WritingAction) async throws -> String
}
