import SwiftUI

/// The floating bar at the bottom of the editor: dictate, polish, and quick utilities.
struct ComposerDock: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme

    @State private var showHistory = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            bar(showLabels: true)
            bar(showLabels: false)
        }
        .popover(isPresented: $showHistory, arrowEdge: .top) {
            ComposerHistoryView(model: model, theme: theme) { showHistory = false }
        }
    }

    private func bar(showLabels: Bool) -> some View {
        HStack(spacing: 4) {
            DictationButton(model: model, theme: theme, showTitle: showLabels)
            divider
            polishButton(
                "Fix",
                icon: "text.badge.checkmark",
                action: .improveGrammar,
                key: "1",
                showLabels: showLabels
            )
            polishButton("Polish", icon: "sparkles", action: .professionalize, key: "2", showLabels: showLabels)
            polishButton(
                "Shorten",
                icon: "arrow.down.right.and.arrow.up.left",
                action: .makeConcise,
                key: "3",
                showLabels: showLabels
            )
            toneMenu(showLabels: showLabels)
            divider
            utilities
        }
        .padding(6)
        .background(theme.surface, in: Capsule())
        .overlay(Capsule().stroke(theme.border))
        .shadow(color: .black.opacity(theme.isDark ? 0.45 : 0.12), radius: 24, y: 10)
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.border)
            .frame(width: 1, height: 22)
            .padding(.horizontal, 4)
    }

    private var isWritingToolDisabled: Bool {
        !model.hasContent || model.isBusy || model.isRecording
    }

    private func polishButton(
        _ title: String,
        icon: String,
        action: WritingAction,
        key: KeyEquivalent,
        showLabels: Bool
    ) -> some View {
        Button {
            model.apply(action)
        } label: {
            DockLabel(title: title, icon: icon, showTitle: showLabels, isBusy: model.phase == .enhancing(action))
        }
        .buttonStyle(DockButtonStyle(theme: theme))
        .keyboardShortcut(key, modifiers: .command)
        .disabled(isWritingToolDisabled)
        .help("\(title)  ⌘\(key.character)")
    }

    private func toneMenu(showLabels: Bool) -> some View {
        Menu {
            ForEach(ComposerViewModel.tones, id: \.self) { tone in
                Button(tone) { model.apply(.changeTone(tone)) }
            }
        } label: {
            DockLabel(title: "Tone", icon: "theatermasks", showTitle: showLabels, isBusy: isToneBusy)
                .modifier(DockHover(theme: theme))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(isWritingToolDisabled)
        .help("Change tone")
    }

    private var isToneBusy: Bool {
        if case .enhancing(.changeTone) = model.phase {
            return true
        }
        return false
    }

    private var utilities: some View {
        HStack(spacing: 2) {
            iconButton("Undo", icon: "arrow.uturn.backward") { NativeTextEditorActions.undo() }
            iconButton("Redo", icon: "arrow.uturn.forward") { NativeTextEditorActions.redo() }

            iconButton("History", icon: "clock.arrow.circlepath") { showHistory.toggle() }

            iconButton("Copy all  ⇧⌘C", icon: model.hasCopied ? "checkmark" : "doc.on.doc") { model.copyText() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(model.text.isEmpty)

            iconButton("Clear  ⇧⌘⌫", icon: "trash") { model.clear() }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
                .disabled(model.text.isEmpty)
        }
    }

    private func iconButton(_ help: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            DockLabel(title: help, icon: icon, showTitle: false)
        }
        .buttonStyle(DockButtonStyle(theme: theme))
        .help(help)
    }
}

private struct DictationButton: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme
    let showTitle: Bool

    var body: some View {
        Button(action: model.toggleRecording) {
            HStack(spacing: 9) {
                if case let .recording(startedAt) = model.phase {
                    WaveformView(color: .white)
                    timer(since: startedAt)
                    Text(model.isPromptMode ? "Send" : "Stop")
                        .font(.system(size: 12.5, weight: .semibold))
                } else {
                    Image(systemName: model.isPromptMode ? "sparkles" : "mic.fill")
                        .font(.system(size: 14, weight: .semibold))
                    if showTitle {
                        Text(model.isPromptMode ? "Ask" : "Dictate")
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(minWidth: 44, minHeight: 40)
            .background(Capsule().fill(model.isRecording ? Color.composerRecording : theme.accent))
            .overlay {
                if model.isRecording {
                    Capsule().stroke(Color.composerRecording.opacity(0.35), lineWidth: 4)
                }
            }
            .opacity(model.isBusy ? 0.5 : 1)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.space, modifiers: .option)
        .disabled(model.isBusy)
        .help(helpText)
    }

    private var helpText: String {
        if model.isRecording {
            return model.isPromptMode ? "Send prompt  ⌥Space" : "Stop dictation  ⌥Space"
        }
        return model.isPromptMode ? "Dictate a prompt  ⌥Space" : "Start dictation  ⌥Space"
    }

    private func timer(since startedAt: Date) -> some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { context in
            let seconds = max(0, Int(context.date.timeIntervalSince(startedAt)))
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .font(.system(size: 12.5, weight: .medium))
                .monospacedDigit()
        }
    }
}
