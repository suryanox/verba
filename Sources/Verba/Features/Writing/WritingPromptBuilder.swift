import Foundation

struct WritingPromptBuilder {
    func prompt(for action: WritingAction, text: String) -> String {
        let instruction: String
        switch action {
        case .answerPrompt:
            return answerPrompt(for: text)
        case .condenseNotes:
            return notesPrompt(for: text)
        case .explainArticle:
            return teacherPrompt(for: text)
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

    private func notesPrompt(for part: String) -> String {
        """
        Below is one part of a longer article. Write short bullet notes of its key facts and ideas.

        Use at most 8 bullets, each one short line starting with "- ".
        Only use what the text says. Do not add outside knowledge, opinions, or commentary.

        Text:
        \(part)
        """
    }

    private func teacherPrompt(for article: String) -> String {
        """
        You are an old-school teacher explaining an article to a complete beginner who knows nothing about \
        the subject.

        Write exactly four short lines in plain text, with no markdown symbols and no bullets:
        The idea: one sentence saying what this is really about.
        Why it matters: one sentence.
        How it works: two to four short sentences. Use one simple everyday comparison.
        Remember: one short sentence the reader should take away.

        Rules:
        - Teach the idea itself. Never write "this article", "the author", "the text", or "the piece".
        - Use short, plain words. Explain any technical word the first time you use it.
        - No hype, no filler, no buzzwords, no opinions.
        - Use only facts found below. Never invent details. If something is unclear, leave it out.
        - Keep the whole answer under 110 words.

        Article:
        \(article)
        """
    }
}
