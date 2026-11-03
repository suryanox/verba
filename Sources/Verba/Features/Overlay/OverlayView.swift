import SwiftUI

struct OverlayView: View {
    @ObservedObject var model: OverlayViewModel

    var body: some View {
        Group {
            switch model.presentation {
            case let .recording(startedAt):
                recordingView(startedAt: startedAt)
            case .transcribing:
                statusView(title: "Transcribing…", systemImage: "waveform")
            case let .reviewing(transcript):
                reviewView(transcript: transcript)
            case nil:
                EmptyView()
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15)))
        .shadow(radius: 12)
    }

    private func recordingView(startedAt: Date) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "mic.fill")
                .foregroundStyle(.red)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date.timeIntervalSince(startedAt), format: .number.precision(.fractionLength(0)))
                    .monospacedDigit()
            }
            Button("Stop", systemImage: "stop.fill") {
                model.onStop?()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func statusView(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .frame(minWidth: 160)
    }

    private func reviewView(transcript: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(transcript)
                .lineLimit(4)
            HStack {
                Button("Insert", systemImage: "checkmark") {
                    model.onInsert?(transcript)
                }
                .buttonStyle(.borderedProminent)
                actionButton("Grammar", systemImage: "text.badge.checkmark") {
                    model.onWritingAction?(.improveGrammar)
                }
                actionButton("Professional", systemImage: "briefcase") {
                    model.onWritingAction?(.professionalize)
                }
            }
        }
        .frame(maxWidth: 360, alignment: .leading)
    }

    private func actionButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, systemImage: systemImage) {
            action()
        }
        .buttonStyle(.bordered)
    }
}
