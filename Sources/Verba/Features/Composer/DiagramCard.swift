import SwiftUI

/// Draws the steps of a research as a simple flow: numbered boxes joined by arrows.
struct DiagramCard: View {
    let theme: ComposerTheme
    let steps: [String]
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("DIAGRAM", systemImage: "arrow.triangle.branch")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(theme.muted)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(DockButtonStyle(theme: theme))
                .help("Hide diagram")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        if index > 0 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.muted)
                        }
                        node(number: index + 1, title: step)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 760, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.border))
        .shadow(color: .black.opacity(theme.isDark ? 0.35 : 0.1), radius: 16, y: 6)
    }

    private func node(number: Int, title: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return HStack(spacing: 8) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(theme.accent))

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: 200)
        .background(theme.text.opacity(0.06), in: shape)
        .overlay(shape.stroke(theme.border))
    }
}
