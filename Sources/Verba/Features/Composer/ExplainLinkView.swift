import AppKit
import SwiftUI

/// Popover where you paste an article link to have it explained in plain language.
struct ExplainLinkView: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme
    var onDone: () -> Void = {}

    @State private var link = ""
    @FocusState private var isFocused: Bool

    private var canExplain: Bool {
        ArticleURL.parse(link) != nil && !model.isBusy && !model.isRecording
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPLAIN A LINK")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(theme.muted)

            TextField("Paste an article link", text: $link)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(theme.text.opacity(0.06), in: fieldShape)
                .overlay(fieldShape.stroke(theme.border))
                .focused($isFocused)
                .onSubmit(submit)

            Text("You get a short lesson in plain words, added to your document. The AI runs on this Mac.")
                .font(.system(size: 11.5))
                .foregroundStyle(theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button(action: submit) {
                    Text("Explain")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 32)
                        .background(Capsule().fill(canExplain ? theme.accent : theme.muted.opacity(0.4)))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(!canExplain)
            }
        }
        .foregroundStyle(theme.text)
        .padding(16)
        .frame(width: 340)
        .background(theme.background)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .onAppear {
            prefillFromClipboard()
            isFocused = true
        }
    }

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
    }

    private func submit() {
        guard canExplain else { return }
        model.explainLink(link)
        onDone()
    }

    private func prefillFromClipboard() {
        guard link.isEmpty,
              let copied = NSPasteboard.general.string(forType: .string)?
              .trimmingCharacters(in: .whitespacesAndNewlines),
              copied.lowercased().hasPrefix("http"),
              ArticleURL.parse(copied) != nil else { return }
        link = copied
    }
}
