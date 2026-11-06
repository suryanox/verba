import AppKit
import SwiftUI

struct ComposerView: View {
    @ObservedObject var model: ComposerViewModel

    private var wordCount: Int {
        model.text.split { $0.isWhitespace || $0.isNewline }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            titlebar
            Divider().overlay(.white.opacity(0.08))

            HStack(alignment: .top, spacing: 28) {
                controlRail
                editor
            }
            .frame(maxWidth: 1040, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 34)
            .padding(.vertical, 30)
        }
        .frame(minWidth: 820, minHeight: 590)
        .background(Color.verbaCanvas.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var titlebar: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.verbaAccent)
                .frame(width: 25, height: 25)
                .background(Color.verbaAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

            Text("Verba")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 13)
        .background(Color.verbaChrome.opacity(0.86))
    }

    private var controlRail: some View {
        VStack(alignment: .leading, spacing: 0) {
            micButton
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 12)

            stateView
                .frame(maxWidth: .infinity)
                .padding(.bottom, 22)

            Divider().overlay(.white.opacity(0.1))
                .padding(.bottom, 18)

            Text("POLISH")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.bottom, 9)

            VStack(spacing: 2) {
                actionRow("Grammar", icon: "text.badge.checkmark", action: .improveGrammar)
                actionRow("Professional", icon: "briefcase", action: .professionalize)
                actionRow("Concise", icon: "arrow.down.right.and.arrow.up.left", action: .makeConcise)
            }

            Spacer(minLength: 20)

            Divider().overlay(.white.opacity(0.1))
                .padding(.bottom, 13)

            stats
            utilityActions
        }
        .frame(minWidth: 166, maxWidth: 166, maxHeight: .infinity, alignment: .top)
    }

    private var micButton: some View {
        Button(action: model.toggleRecording) {
            Image(systemName: model.isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(model.isRecording ? Color.verbaRecording : Color.verbaAccent, in: Circle())
                .overlay {
                    if model.isRecording {
                        Circle().stroke(Color.verbaRecording.opacity(0.35), lineWidth: 7)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(model.isBusy)
        .help(model.isRecording ? "Stop speaking" : "Speak")
    }

    @ViewBuilder
    private var stateView: some View {
        switch model.phase {
        case let .recording(startedAt):
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(Color.verbaRecording).frame(width: 6, height: 6)
                    Text("Listening")
                }
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(context.date.timeIntervalSince(startedAt), format: .number.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
            .font(.system(size: 12, weight: .medium))
        case .enhancing:
            Label("Working", systemImage: "ellipsis")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.42))
        case .error:
            Label("Needs attention", systemImage: "exclamationmark.triangle")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.verbaWarning)
        case .ready:
            Text("Ready")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.36))
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Untitled")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text("Plain text")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.bottom, 15)

            ZStack(alignment: .topLeading) {
                NativeTextEditor(text: $model.text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if model.text.isEmpty && !model.isBusy {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Start writing")
                            .font(.system(size: 19, weight: .regular))
                            .foregroundStyle(.white.opacity(0.28))
                        Text("Type here or use the microphone.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.18))
                    }
                    .padding(.leading, 18)
                    .padding(.top, 24)
                    .allowsHitTesting(false)
                }
            }
            .background(Color.verbaPaper, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.09)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("DOCUMENT")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.3))
            HStack {
                Text("Words")
                Spacer()
                Text("\(wordCount)")
            }
            HStack {
                Text("Characters")
                Spacer()
                Text("\(model.text.count)")
            }
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.white.opacity(0.35))
        .padding(.bottom, 14)
    }

    private var utilityActions: some View {
        HStack(spacing: 13) {
            utilityButton("Undo", icon: "arrow.uturn.backward") { NativeTextEditorActions.undo() }
                .keyboardShortcut("z", modifiers: .command)
            utilityButton("Redo", icon: "arrow.uturn.forward") { NativeTextEditorActions.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            utilityButton("Copy", icon: model.hasCopied ? "checkmark" : "doc.on.doc") { model.copyText() }
                .disabled(model.text.isEmpty)
        }
    }

    private func utilityButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.46))
        }
        .buttonStyle(.plain)
        .help(label)
    }

    private func actionRow(_ title: String, icon: String, action: WritingAction) -> some View {
        Button { model.apply(action) } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .foregroundStyle(model.text.isEmpty || model.isBusy ? .white.opacity(0.2) : .white.opacity(0.58))
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(model.text.isEmpty || model.isBusy)
        .help(title)
    }
}

private extension Color {
    static let verbaCanvas = Color(nsColor: .windowBackgroundColor)
    static let verbaChrome = Color(nsColor: .controlBackgroundColor)
    static let verbaPaper = Color(nsColor: .textBackgroundColor).opacity(0.1)
    static let verbaAccent = Color(red: 0.48, green: 0.39, blue: 0.95)
    static let verbaRecording = Color(red: 0.94, green: 0.27, blue: 0.32)
    static let verbaWarning = Color(red: 0.95, green: 0.66, blue: 0.24)
}
