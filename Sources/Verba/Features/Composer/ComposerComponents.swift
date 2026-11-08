import SwiftUI

/// Hover and press feedback shared by every button in the toolbar and header.
struct DockHover: ViewModifier {
    let theme: ComposerTheme
    var isPressed = false

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isEnabled ? theme.text.opacity(0.88) : theme.muted.opacity(0.45))
            .background(Capsule().fill(theme.text.opacity(fillOpacity)))
            .contentShape(Capsule())
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private var fillOpacity: Double {
        guard isEnabled else { return 0 }
        if isPressed {
            return 0.16
        }
        return isHovered ? 0.08 : 0
    }
}

struct DockButtonStyle: ButtonStyle {
    let theme: ComposerTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(DockHover(theme: theme, isPressed: configuration.isPressed))
    }
}

/// Icon with an optional title. Shows a small spinner while its action is running.
struct DockLabel: View {
    let title: String
    let icon: String
    var showTitle = true
    var isBusy = false

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .frame(width: 16, height: 16)

            if showTitle {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
            }
        }
        .padding(.horizontal, showTitle ? 12 : 9)
        .frame(minWidth: 34, minHeight: 34)
    }
}

/// Animated bars shown while the microphone is open.
struct WaveformView: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2.5) {
                ForEach(0 ..< 5, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .frame(width: 3, height: 6 + 12 * abs(sin(time * 4 + Double(index) * 0.9)))
                }
            }
            .frame(height: 20)
        }
    }
}
