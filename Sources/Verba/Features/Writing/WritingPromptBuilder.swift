import Foundation

struct WritingPromptBuilder {
    func prompt(for action: WritingAction, text: String) -> String {
        let instruction: String
        switch action {
        case .improveGrammar:
            instruction = "Correct grammar, spelling, punctuation, and awkward phrasing."
        case .professionalize:
            instruction = "Rewrite this in a clear, polished, professional tone."
        case .makeConcise:
            instruction = "Make this more concise while preserving the meaning."
        case let .changeTone(tone):
            instruction = "Rewrite this using a \(tone) tone while preserving the meaning."
        }

        return """
        \(instruction)
        Return only the rewritten text, without quotation marks or commentary.

        Text:
        \(text)
        """
    }
}
