import SwiftUI

/// A floating card with an icon, a small label, a message, and a spinner. Used while the AI is working.
struct ActivityCard: View {
    let theme: ComposerTheme
    let icon: String
    let label: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.accent)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(theme.muted)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            ProgressView()
                .controlSize(.small)
                .frame(width: 28, height: 28)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: 620, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.border))
        .shadow(color: .black.opacity(theme.isDark ? 0.35 : 0.1), radius: 16, y: 6)
    }
}
