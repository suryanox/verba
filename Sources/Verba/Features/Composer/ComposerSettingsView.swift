import SwiftUI

/// Popover with appearance controls. Everything here persists between launches.
struct ComposerSettingsView: View {
    @ObservedObject var preferences: ComposerPreferences

    private var theme: ComposerTheme { preferences.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section("Theme") {
                HStack(spacing: 10) {
                    ForEach(ComposerTheme.allCases) { option in
                        swatch(option)
                    }
                }
            }

            section("Typeface") {
                Picker("Typeface", selection: $preferences.font) {
                    ForEach(ComposerFont.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            section("Size", value: "\(Int(preferences.fontSize)) pt") {
                Slider(value: $preferences.fontSize, in: 14...34, step: 1)
            }

            section("Line spacing", value: String(format: "%.2f", preferences.lineHeight)) {
                Slider(value: $preferences.lineHeight, in: 1.1...2.0)
            }

            section("Column") {
                Picker("Column", selection: $preferences.column) {
                    ForEach(ComposerColumn.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Toggle(isOn: $preferences.focusMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus mode")
                        .font(.system(size: 12.5, weight: .medium))
                    Text("Hide the toolbar while you type. Move the mouse to bring it back.")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .tint(theme.accent)

            Button("Reset typography") { preferences.resetTypography() }
                .buttonStyle(DockButtonStyle(theme: theme))
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 6)
        }
        .foregroundStyle(theme.text)
        .tint(theme.accent)
        .padding(18)
        .frame(width: 310)
        .background(theme.background)
        .preferredColorScheme(theme.isDark ? .dark : .light)
    }

    private func section<Content: View>(
        _ title: String,
        value: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                Spacer()
                if let value {
                    Text(value)
                        .font(.system(size: 11, weight: .medium))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(theme.muted)

            content()
        }
    }

    private func swatch(_ option: ComposerTheme) -> some View {
        let isSelected = preferences.theme == option
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return Button {
            preferences.theme = option
        } label: {
            VStack(spacing: 6) {
                Text("Aa")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(option.text)
                    .frame(width: 56, height: 42)
                    .background(option.background, in: shape)
                    .overlay(shape.stroke(isSelected ? option.accent : theme.border, lineWidth: isSelected ? 2 : 1))
                Text(option.title)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(isSelected ? theme.text : theme.muted)
            }
        }
        .buttonStyle(.plain)
        .help(option.title)
    }
}
