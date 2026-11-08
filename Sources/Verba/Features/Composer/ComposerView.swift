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
                promptToggle
                ComposerDock(model: model, theme: theme)
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
            NativeTextEditor(text: $model.text, style: editorStyle, isDictating: model.isRecording)

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

    // MARK: - Prompt mode

    private var promptToggle: some View {
        Toggle(isOn: $model.isPromptMode) {
            Text("Dictate a prompt")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(model.isPromptMode ? theme.text : theme.muted)
        }
        .toggleStyle(.checkbox)
        .tint(theme.accent)
        .disabled(model.isRecording || model.isBusy)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(theme.surface, in: Capsule())
        .overlay(Capsule().stroke(theme.border))
        .help("Send what you dictate to the on-device AI as a prompt. Its answer is added to your document.")
    }

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
        let words = model.wordCount
        guard words > 0 else { return "0 words" }
        let noun = words == 1 ? "word" : "words"
        return "\(words) \(noun) · \(model.text.count) chars · \(model.readingMinutes) min read"
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

                Button { model.openSpeechSettings() } label: {
                    Text("Settings")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10)
                        .frame(minHeight: 28)
                }
                .buttonStyle(DockButtonStyle(theme: theme))

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
