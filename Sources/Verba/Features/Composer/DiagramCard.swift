import SwiftUI

/// Shows the whiteboard above the controls. It shrinks to fit narrow windows and has a small close button.
struct DiagramCard: View {
    let theme: ComposerTheme
    let steps: [String]
    let onClose: () -> Void

    var body: some View {
        let layout = WhiteboardLayout(count: steps.count)
        let width = layout.boardSize.width

        GeometryReader { proxy in
            WhiteboardView(steps: steps)
                .scaleEffect(min(1, proxy.size.width / width), anchor: .topLeading)
        }
        .aspectRatio(width / layout.totalHeight, contentMode: .fit)
        .frame(maxWidth: width)
        .shadow(color: .black.opacity(theme.isDark ? 0.5 : 0.18), radius: 18, y: 8)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(white: 0.25))
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color(white: 0.93)))
                .overlay(Circle().stroke(Color(white: 0.7)))
        }
        .buttonStyle(.plain)
        .padding(12)
        .help("Hide diagram")
    }
}
