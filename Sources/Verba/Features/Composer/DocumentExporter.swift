import AppKit
import UniformTypeIdentifiers

@MainActor
enum DocumentExporter {
    /// Asks where to save, then writes the text as a plain .txt file. Does nothing if the person cancels.
    static func export(text: String, title: String) throws {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true

        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        panel.nameFieldStringValue = (name.isEmpty ? "Untitled" : name) + ".txt"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
