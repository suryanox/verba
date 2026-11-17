import SwiftUI

/// Picks what you're doing: writing, asking the AI, or researching a link.
/// It stays on screen in every mode, and the controls below it change to match.
struct ModeSwitcher: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme

    private var isLocked: Bool {
        model.isRecording || model.isBusy
    }

    var body: some View {
        HStack(spacing: 2) {
            segment(.normal, title: "Write", icon: "square.and.pencil", help: "Write and edit")
            segment(.prompt, title: "Ask AI", icon: "sparkles", help: "Dictate a prompt for the AI")
            segment(
                .research,
                title: "Research",
                icon: "graduationcap",
                help: "Explain an article link  ⌘L",
                shortcut: KeyboardShortcut("l", modifiers: .command)
            )
        }
        .padding(3)
        .background(theme.surface, in: Capsule())
        .overlay(Capsule().stroke(theme.border))
        .shadow(color: .black.opacity(theme.isDark ? 0.35 : 0.08), radius: 14, y: 5)
        .opacity(isLocked ? 0.55 : 1)
        .disabled(isLocked)
        .animation(.snappy(duration: 0.2), value: model.mode)
    }

    private func segment(
        _ mode: ComposerMode,
        title: String,
        icon: String,
        help: String,
        shortcut: KeyboardShortcut? = nil
    ) -> some View {
        let isSelected = model.mode == mode
        return Button {
            model.mode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Color.white : theme.muted)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(Capsule().fill(isSelected ? theme.accent : Color.clear))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcut)
        .help(help)
    }
}
