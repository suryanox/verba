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

        Pay most attention to three things: what the work is about, how it was done (the method or steps), \
        and what was found (results, numbers, outcomes).

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

        Answer in exactly this format, in plain text with no markdown symbols:

        About: one or two short sentences saying what this is really about and why it matters.
        How:
        - three to five short steps, in order, showing how they did it or how it works
        Results:
        - two to four short lines saying what they found or what came out of it
        Diagram: three to five very short step names (two to four words each) separated by ">"

        Rules:
        - Teach the idea itself. Never write "this article", "the author", "the text", or "the piece".
        - Use short, plain words. Explain any technical word the first time you use it.
        - Put one simple everyday comparison inside About or How.
        - No hype, no filler, no buzzwords, no opinions.
        - Use only facts found below. Never invent details or numbers.
        - If the article does not say how it was done, or what the results were, write "Not stated." \
        for that part instead of guessing.
        - The Diagram steps must follow the same order as the How steps.
        - Keep the whole answer under 150 words.

        Article:
        \(article)
        """
    }
}
