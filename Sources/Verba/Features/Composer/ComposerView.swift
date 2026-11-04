import SwiftUI

struct ComposerView: View {
    @ObservedObject var model: ComposerViewModel

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        introduction
                        editorCard
                        enhancementBar
                    }
                    .padding(.horizontal, 42)
                    .padding(.vertical, 36)
                }
            }
        }
        .frame(minWidth: 820, minHeight: 650)
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.055, green: 0.065, blue: 0.09), Color(red: 0.095, green: 0.075, blue: 0.14)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(LinearGradient(colors: [.verbaViolet, .verbaBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "waveform")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text("Verba")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("Your words, polished")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Label("Private workspace", systemImage: "lock.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.06), in: Capsule())
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(.black.opacity(0.16))
        .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.07)).frame(height: 1) }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Say it. Shape it. Ship it.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Speak freely, then turn your thoughts into words worth sending.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.52))
        }
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("COMPOSER", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.42))
                Spacer()
                if !model.text.isEmpty {
                    Text("\(model.text.count) characters")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                    Button("Clear", systemImage: "xmark") { model.clear() }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.text)
                    .font(.system(size: 19, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 245)
                    .padding(.top, 18)

                if model.text.isEmpty && !model.isBusy {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(.white.opacity(0.22))
                        Text("Your words will appear here…")
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.28))
                        Text("Press Speak and start talking naturally.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.2))
                    }
                    .padding(.top, 34)
                    .allowsHitTesting(false)
                }
            }

            Divider().overlay(.white.opacity(0.08))
            composerFooter
        }
        .padding(20)
        .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.1)))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
    }

    private var composerFooter: some View {
        HStack(spacing: 14) {
            Button(action: model.toggleRecording) {
                HStack(spacing: 9) {
                    Image(systemName: model.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(model.isRecording ? "Stop speaking" : "Speak")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 17)
                .padding(.vertical, 11)
                .background(model.isRecording ? Color.verbaRose : Color.verbaViolet, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(model.isBusy)

            phaseStatus
            Spacer()
            Button(action: model.copyText) {
                Label(model.hasCopied ? "Copied" : "Copy text", systemImage: model.hasCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(model.text.isEmpty ? .white.opacity(0.22) : .white.opacity(0.72))
            }
            .buttonStyle(.plain)
            .disabled(model.text.isEmpty)
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var phaseStatus: some View {
        switch model.phase {
        case let .recording(startedAt):
            HStack(spacing: 8) {
                Circle().fill(Color.verbaRose).frame(width: 7, height: 7)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(context.date.timeIntervalSince(startedAt), format: .number.precision(.fractionLength(0)))
                        .monospacedDigit()
                }
                .foregroundStyle(.white.opacity(0.58))
            }
        case .transcribing:
            Label("Transcribing…", systemImage: "waveform")
                .foregroundStyle(.white.opacity(0.48))
        case let .enhancing(action):
            Label(action.title, systemImage: "sparkles")
                .foregroundStyle(.white.opacity(0.48))
        case let .error(message):
            Button {
                model.dismissError()
            } label: {
                Label(message, systemImage: "exclamationmark.triangle")
                    .lineLimit(1)
                    .foregroundStyle(Color.verbaGold)
            }
            .buttonStyle(.plain)
        case .ready:
            EmptyView()
        }
    }

    private var enhancementBar: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("REFINE YOUR WORDS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.38))

            HStack(spacing: 10) {
                enhancementButton("Grammar", icon: "text.badge.checkmark", action: .improveGrammar)
                enhancementButton("Professional", icon: "briefcase", action: .professionalize)
                enhancementButton("Concise", icon: "arrow.down.right.and.arrow.up.left", action: .makeConcise)
            }
        }
    }

    private func enhancementButton(_ title: String, icon: String, action: WritingAction) -> some View {
        Button { model.apply(action) } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(model.text.isEmpty || model.isBusy ? .white.opacity(0.25) : .white.opacity(0.72))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white.opacity(0.06), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.09)))
        }
        .buttonStyle(.plain)
        .disabled(model.text.isEmpty || model.isBusy)
    }
}

private extension WritingAction {
    var title: String {
        switch self {
        case .improveGrammar: return "Improving grammar…"
        case .professionalize: return "Professionalizing…"
        case .makeConcise: return "Making concise…"
        case let .changeTone(tone): return "Changing tone to \(tone)…"
        }
    }
}

private extension Color {
    static let verbaViolet = Color(red: 0.42, green: 0.28, blue: 0.95)
    static let verbaBlue = Color(red: 0.16, green: 0.48, blue: 0.95)
    static let verbaRose = Color(red: 0.9, green: 0.2, blue: 0.38)
    static let verbaGold = Color(red: 1.0, green: 0.72, blue: 0.22)
}
