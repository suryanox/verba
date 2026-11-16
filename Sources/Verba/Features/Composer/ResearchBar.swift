import AppKit
import SwiftUI

/// Research mode: the toolbar is replaced by a single field where you paste an article link.
struct ResearchBar: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme

    @State private var link = ""
    @FocusState private var isFocused: Bool

    private var canExplain: Bool {
        ArticleURL.parse(link) != nil && !model.isBusy
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "graduationcap")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.accent)
                .padding(.leading, 12)

            TextField("Paste an article link", text: $link)
                .textFieldStyle(.plain)
                .font(.system(size: 13.5))
                .foregroundStyle(theme.text)
                .focused($isFocused)
                .onSubmit(submit)

            Button(action: submit) {
                Text("Explain")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 36)
                    .background(Capsule().fill(canExplain ? theme.accent : theme.muted.opacity(0.4)))
            }
            .buttonStyle(.plain)
            .disabled(!canExplain)
            .help("Explain this page in plain words  Return")

            Button { model.exitMode() } label: {
                DockLabel(title: "Close", icon: "xmark", showTitle: false)
            }
            .buttonStyle(DockButtonStyle(theme: theme))
            .keyboardShortcut(.cancelAction)
            .help("Back to all tools  Esc")
        }
        .padding(6)
        .frame(maxWidth: 560)
        .background(theme.surface, in: Capsule())
        .overlay(Capsule().stroke(theme.border))
        .shadow(color: .black.opacity(theme.isDark ? 0.45 : 0.12), radius: 24, y: 10)
        .onAppear {
            prefillFromClipboard()
            isFocused = true
        }
    }

    private func submit() {
        guard canExplain else { return }
        model.explainLink(link)
    }

    /// If you just copied a link, it's already waiting here.
    private func prefillFromClipboard() {
        guard link.isEmpty,
              let copied = NSPasteboard.general.string(forType: .string)?
              .trimmingCharacters(in: .whitespacesAndNewlines),
              copied.lowercased().hasPrefix("http"),
              ArticleURL.parse(copied) != nil else { return }
        link = copied
    }
}
