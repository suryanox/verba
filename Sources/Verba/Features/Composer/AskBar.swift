import SwiftUI

/// Ask AI mode: the toolbar is replaced by a single Ask AI button.
/// Everything else returns once the answer arrives, as soon as you type or paste, or when you switch back to Write.
struct AskBar: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme

    var body: some View {
        DockGroup(theme: theme, caption: "Input") {
            DictationButton(model: model, theme: theme, showTitle: true)
        }
    }
}
