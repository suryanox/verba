import SwiftUI

/// A rounded capsule holding one group of related controls, with a small caption underneath.
struct DockGroup<Content: View>: View {
    let theme: ComposerTheme
    let caption: String?
    let content: Content

    init(theme: ComposerTheme, caption: String? = nil, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.caption = caption
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 2) {
                content
            }
            .padding(.horizontal, 6)
            .frame(height: 52)
            .background(theme.surface, in: Capsule())
            .overlay(Capsule().stroke(theme.border))
            .shadow(color: .black.opacity(theme.isDark ? 0.4 : 0.1), radius: 20, y: 8)

            if let caption {
                Text(caption.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(theme.muted.opacity(0.85))
            }
        }
    }
}

/// The toolbar shown while writing, split by purpose: input, improving the text, and managing the document.
struct ComposerDock: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme

    @State private var showHistory = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(showLabels: true)
            row(showLabels: false)
        }
        .popover(isPresented: $showHistory, arrowEdge: .top) {
            ComposerHistoryView(model: model, theme: theme) { showHistory = false }
        }
    }

    private func row(showLabels: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            DockGroup(theme: theme, caption: "Input") {
                DictationButton(model: model, theme: theme, showTitle: showLabels)
            }

            DockGroup(theme: theme, caption: "Improve") {
                improvements(showLabels: showLabels)
            }

            DockGroup(theme: theme, caption: "Manage") {
                management
            }
        }
    }

    // MARK: - Improve

    private var isWritingToolDisabled: Bool {
        !model.hasContent || model.isBusy || model.isRecording
    }

    @ViewBuilder
    private func improvements(showLabels: Bool) -> some View {
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

    // MARK: - Manage

    @ViewBuilder
    private var management: some View {
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

    private func iconButton(_ help: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            DockLabel(title: help, icon: icon, showTitle: false)
        }
        .buttonStyle(DockButtonStyle(theme: theme))
        .help(help)
    }
}

struct DictationButton: View {
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
                        Text(model.isPromptMode ? "Ask AI" : "Dictate")
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
