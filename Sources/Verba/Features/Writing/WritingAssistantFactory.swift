@MainActor
enum WritingAssistantFactory {
    /// The on-device assistant when this Mac supports it, otherwise one that explains why it can't help.
    static func make() -> WritingAssistant {
        if #available(macOS 26.0, *) {
            #if canImport(FoundationModels)
                return FoundationModelsWritingAssistant()
            #else
                return UnavailableWritingAssistant()
            #endif
        }
        return UnavailableWritingAssistant()
    }
}
