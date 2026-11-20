import AppKit
import SwiftUI

struct ComposerView: View {
    @ObservedObject var model: ComposerViewModel
    @ObservedObject var preferences: ComposerPreferences

    @State private var showSettings = false
    @State private var chromeVisible = true

    private var theme: ComposerTheme {
        preferences.theme
    }

    /// In focus mode the header and toolbar fade out while typing and return when the mouse moves.
    private var isChromeHidden: Bool {
        guard preferences.focusMode, !chromeVisible, !showSettings else { return false }
        if case .error = model.phase {
            return false
        }
        return !model.isRecording && !model.isBusy
    }

    /// How tall the controls floating at the bottom are right now, so the text cursor stays off them.
    private var bottomChromeHeight: CGFloat {
        let controls: CGFloat = model.mode == .explain ? 132 : 150
        var hasStatusCard = model.isPromptActive || model.isLinkActive
        if case .error = model.phase { hasStatusCard = true }
        return controls + (hasStatusCard ? 84 : 0) + diagramHeight
    }

    /// The whiteboard is taller when it needs two rows of steps.
    private var diagramHeight: CGFloat {
        if model.diagram.isEmpty { return 0 }
        return model.diagram.count <= 4 ? 170 : 270
    }

    private var editorStyle: EditorStyle {
        EditorStyle(
            font: preferences.font.nsFont(size: preferences.fontSize),
            textColor: theme.nsText,
            caretColor: theme.nsAccent,
            selectionColor: theme.nsAccent.withAlphaComponent(0.28),
            lineHeightMultiple: preferences.lineHeight,
            columnWidth: preferences.column.width
        )
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            editor

            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
            }

            VStack(spacing: 12) {
                Spacer(minLength: 0)
                errorBanner
                promptCard
                linkCard
                diagramCard
                bottomControls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
            .opacity(isChromeHidden ? 0 : 1)
            .allowsHitTesting(!isChromeHidden)
        }
        .ignoresSafeArea()
        .frame(minWidth: 720, minHeight: 520)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .animation(.easeInOut(duration: 0.2), value: isChromeHidden)
        .animation(.snappy(duration: 0.25), value: model.phase)
        .animation(.snappy(duration: 0.25), value: model.mode)
        .onChange(of: model.text) { _, _ in
            if preferences.focusMode {
                chromeVisible = false
            }
        }
        .onContinuousHover { phase in
            if case .active = phase {
                chromeVisible = true
            }
        }
    }

    // MARK: - Editor

    private var editor: some View {
        ZStack(alignment: .top) {
            NativeTextEditor(
                text: $model.text,
                style: editorStyle,
                isDictating: model.isRecording,
                onUserEdit: { model.exitMode() },
                topChromeHeight: isChromeHidden ? 0 : 52,
                bottomChromeHeight: isChromeHidden ? 0 : bottomChromeHeight
            )

            if model.text.isEmpty {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.isRecording ? "Listening…" : "Start writing")
                .font(.system(size: preferences.fontSize + 3, design: preferences.font.swiftUIDesign))
                .foregroundStyle(theme.muted.opacity(0.75))
            Text("Type here, or press ⌥Space and speak.")
                .font(.system(size: 13))
                .foregroundStyle(theme.muted.opacity(0.5))
        }
        .padding(.leading, 5)
        .frame(maxWidth: preferences.column.width, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 80)
        .allowsHitTesting(false)
    }

    // MARK: - Bottom controls

    /// The mode switcher is always there. Below it, the controls follow what you're doing: the full toolbar
    /// while writing, a lone Ask AI button in Ask AI mode, and a link field in Explain mode.
    @ViewBuilder
    private var bottomControls: some View {
        ModeSwitcher(model: model, theme: theme)

        switch model.mode {
        case .normal:
            ComposerDock(model: model, theme: theme).transition(.opacity)
        case .prompt:
            AskBar(model: model, theme: theme).transition(.opacity)
        case .explain:
            if !model.isLinkActive {
                ExplainBar(model: model, theme: theme).transition(.opacity)
            }
        }
    }

    // MARK: - Prompt card

    /// Shows the prompt as you speak it, then while the AI is working on it.
    @ViewBuilder
    private var promptCard: some View {
        if model.isPromptActive {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.isRecording ? "SAY YOUR PROMPT" : "THINKING")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(theme.muted)
                    Text(model.promptText.isEmpty ? "Listening…" : model.promptText)
                        .font(.system(size: 14))
                        .foregroundStyle(model.promptText.isEmpty ? theme.muted : theme.text)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                if model.isRecording {
                    Button { model.cancelPrompt() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(DockButtonStyle(theme: theme))
                    .keyboardShortcut(.cancelAction)
                    .help("Cancel  Esc")
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 10)
            .frame(maxWidth: 620, alignment: .leading)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.border))
            .shadow(color: .black.opacity(theme.isDark ? 0.35 : 0.1), radius: 16, y: 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Explain a link

    @ViewBuilder
    private var diagramCard: some View {
        if !model.diagram.isEmpty {
            DiagramCard(theme: theme, steps: model.diagram) { model.dismissDiagram() }
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var linkCard: some View {
        if model.isLinkActive {
            ActivityCard(
                theme: theme,
                icon: "graduationcap",
                label: "LEARNING",
                message: model.linkStatus.isEmpty ? "Reading the page…" : model.linkStatus
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            TextField("Untitled", text: $model.title)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.text)
                .frame(maxWidth: 240)

            Spacer(minLength: 12)

            Text(statsText)
                .font(.system(size: 11.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(theme.muted)
                .lineLimit(1)

            headerButton("Export as text  ⌘S", icon: "square.and.arrow.down") { model.exportDocument() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(model.text.isEmpty)

            headerButton("Appearance", icon: "textformat.size") { showSettings.toggle() }
                .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                    ComposerSettingsView(preferences: preferences)
                }
        }
        .padding(.leading, 84)
        .padding(.trailing, 18)
        .frame(height: 52)
        .background(headerFade)
        .opacity(isChromeHidden ? 0 : 1)
        .allowsHitTesting(!isChromeHidden)
    }

    private var headerFade: some View {
        LinearGradient(
            colors: [theme.background, theme.background.opacity(0.85), theme.background.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 76)
        .frame(maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    private var statsText: String {
        let words = model.text.wordCount
        guard words > 0 else { return "0 words" }
        let noun = words == 1 ? "word" : "words"
        return "\(words) \(noun) · \(model.text.count) chars · \(model.text.readingMinutes) min read"
    }

    private func headerButton(_ help: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            DockLabel(title: help, icon: icon, showTitle: false)
        }
        .buttonStyle(DockButtonStyle(theme: theme))
        .help(help)
    }

    // MARK: - Errors

    @ViewBuilder
    private var errorBanner: some View {
        if case let .error(message) = model.phase {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.composerWarning)

                Text(message)
                    .font(.system(size: 12.5))
                    .foregroundStyle(theme.text)
                    .lineLimit(2)

                Spacer(minLength: 8)

                if model.errorOpensSettings {
                    Button { model.openSpeechSettings() } label: {
                        Text("Settings")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .frame(minHeight: 28)
                    }
                    .buttonStyle(DockButtonStyle(theme: theme))
                }

                Button { model.dismissError() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(DockButtonStyle(theme: theme))
                .help("Dismiss")
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.border))
            .shadow(color: .black.opacity(theme.isDark ? 0.35 : 0.1), radius: 16, y: 6)
            .frame(maxWidth: 620)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
