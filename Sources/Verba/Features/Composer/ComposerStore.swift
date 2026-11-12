import Foundation

/// Saves the draft, its title, and the version history in UserDefaults.
struct ComposerStore {
    static let historyLimit = 40

    private static let textKey = "verba.draft.text"
    private static let titleKey = "verba.draft.title"
    private static let historyKey = "verba.history"

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func loadText() -> String {
        defaults.string(forKey: Self.textKey) ?? ""
    }

    func loadTitle() -> String {
        defaults.string(forKey: Self.titleKey) ?? ""
    }

    func loadHistory() -> [DocumentVersion] {
        guard let data = defaults.data(forKey: Self.historyKey) else { return [] }
        return (try? JSONDecoder().decode([DocumentVersion].self, from: data)) ?? []
    }

    func saveDraft(text: String, title: String) {
        defaults.set(text, forKey: Self.textKey)
        defaults.set(title, forKey: Self.titleKey)
    }

    func saveHistory(_ history: [DocumentVersion]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: Self.historyKey)
    }
}
