import Foundation

enum WritingAction: Sendable {
    case improveGrammar
    case professionalize
    case makeConcise
    case changeTone(String)
}

protocol WritingAssistant: Sendable {
    func transform(_ text: String, using action: WritingAction) async throws -> String
}
