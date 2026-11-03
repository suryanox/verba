import Foundation

enum WritingAction: Sendable {
    case improveGrammar
    case professionalize
    case makeConcise
    case changeTone(String)
}

@MainActor
protocol WritingAssistant {
    func transform(_ text: String, using action: WritingAction) async throws -> String
}
