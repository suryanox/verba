import SwiftUI

/// Prompt mode: the toolbar is replaced by a single "Ask AI" button.
/// Everything else returns once the answer arrives, or as soon as you type or paste.
struct AskBar: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme

    var body: some View {
        HStack(spacing: 4) {
            DictationButton(model: model, theme: theme, showTitle: true)

            if !model.isRecording, !model.isBusy {
                Button { model.exitMode() } label: {
                    DockLabel(title: "Close", icon: "xmark", showTitle: false)
                }
                .buttonStyle(DockButtonStyle(theme: theme))
                .keyboardShortcut(.cancelAction)
                .help("Back to all tools  Esc")
            }
        }
        .padding(6)
        .background(theme.surface, in: Capsule())
        .overlay(Capsule().stroke(theme.border))
        .shadow(color: .black.opacity(theme.isDark ? 0.45 : 0.12), radius: 24, y: 10)
    }
}
