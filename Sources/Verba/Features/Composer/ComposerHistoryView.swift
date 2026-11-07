import SwiftUI

/// Popover listing saved snapshots of the document, newest first.
struct ComposerHistoryView: View {
    @ObservedObject var model: ComposerViewModel
    let theme: ComposerTheme
    var onRestore: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HISTORY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(theme.muted)
                Spacer()
                if !model.history.isEmpty {
                    Button("Clear") { model.clearHistory() }
                        .buttonStyle(DockButtonStyle(theme: theme))
                        .font(.system(size: 11.5, weight: .medium))
                }
            }

            if model.history.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(model.history) { version in
                            row(version)
                        }
                    }
                }
                .frame(maxHeight: 340)
            }
        }
        .foregroundStyle(theme.text)
        .padding(16)
        .frame(width: 330)
        .background(theme.background)
        .preferredColorScheme(theme.isDark ? .dark : .light)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 22))
                .foregroundStyle(theme.muted)
            Text("No versions yet")
                .font(.system(size: 12.5, weight: .medium))
            Text("Snapshots are saved automatically while you write, dictate, and polish.")
                .font(.system(size: 11.5))
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func row(_ version: DocumentVersion) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return Button {
            model.restore(version)
            onRestore()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(version.label)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text(version.date, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.muted)
                }
                Text(version.text)
                    .font(.system(size: 11.5))
                    .foregroundStyle(theme.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.text.opacity(0.05), in: shape)
            .overlay(shape.stroke(theme.border))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(!model.canRestoreHistory)
        .help("Restore this version. Your current text is saved to history first.")
        .contextMenu {
            Button("Delete version") { model.deleteVersion(version) }
        }
    }
}
