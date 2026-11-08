import Foundation

struct WritingPromptBuilder {
    func prompt(for action: WritingAction, text: String) -> String {
        let instruction: String
        switch action {
        case .answerPrompt:
            return answerPrompt(for: text)
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

        Preserve the original meaning exactly. Do not change the subject, speaker, grammatical person, \
        pronouns, tense, aspect, modality, negation, facts, quantities, names, or point of view. \
        If the text says "I", keep it in first person. Do not invent, omit, or add information. \
        Only make the smallest changes required by the requested operation.
        Return only the rewritten text, without quotation marks or commentary.

        Text:
        \(text)
        """
    }

    private func answerPrompt(for request: String) -> String {
        """
        Follow the request below and write exactly what it asks for.

        The request was dictated by voice, so ignore filler words and minor transcription mistakes.
        Return only the finished text, without quotation marks, a preamble, or commentary.

        Request:
        \(request)
        """
    }
}
