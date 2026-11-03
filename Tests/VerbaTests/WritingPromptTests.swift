import Testing
@testable import Verba

@Test("Grammar prompts request a text-only correction")
func grammarPrompt() {
    let prompt = WritingPromptBuilder().prompt(
        for: .improveGrammar,
        text: "Their going home."
    )

    #expect(prompt.contains("Correct grammar"))
    #expect(prompt.contains("Their going home."))
    #expect(prompt.contains("only the rewritten text"))
}

@Test("Professional prompts preserve the original text as context")
func professionalPrompt() {
    let prompt = WritingPromptBuilder().prompt(
        for: .professionalize,
        text: "Can you send this soon?"
    )

    #expect(prompt.contains("professional tone"))
    #expect(prompt.contains("Can you send this soon?"))
}
