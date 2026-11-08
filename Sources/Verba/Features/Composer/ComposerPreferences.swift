import AppKit
import SwiftUI

// MARK: - Theme

enum ComposerTheme: String, CaseIterable, Identifiable {
    case midnight
    case graphite
    case paper
    case sepia

    private struct Palette {
        let background: UInt32
        let surface: UInt32
        let text: UInt32
        let muted: UInt32
        let accent: UInt32
    }

    var id: String {
        rawValue
    }

    var title: String {
        rawValue.capitalized
    }

    var isDark: Bool {
        self == .midnight || self == .graphite
    }

    var nsBackground: NSColor {
        NSColor(hex: palette.background)
    }

    var nsText: NSColor {
        NSColor(hex: palette.text)
    }

    var nsAccent: NSColor {
        NSColor(hex: palette.accent)
    }

    var background: Color {
        Color(nsColor: nsBackground)
    }

    var surface: Color {
        Color(nsColor: NSColor(hex: palette.surface))
    }

    var text: Color {
        Color(nsColor: nsText)
    }

    var muted: Color {
        Color(nsColor: NSColor(hex: palette.muted))
    }

    var accent: Color {
        Color(nsColor: nsAccent)
    }

    var border: Color {
        text.opacity(isDark ? 0.10 : 0.13)
    }

    private var palette: Palette {
        switch self {
        case .midnight:
            Palette(background: 0x0F1014, surface: 0x181A21, text: 0xE9E7E2, muted: 0x868A96, accent: 0x7C6CF2)
        case .graphite:
            Palette(background: 0x1C1C1E, surface: 0x27272A, text: 0xEDEDED, muted: 0x8D8D93, accent: 0x2E9488)
        case .paper:
            Palette(background: 0xF6F3EC, surface: 0xFFFFFF, text: 0x25221E, muted: 0x8A857A, accent: 0xC8553A)
        case .sepia:
            Palette(background: 0xEEE2CB, surface: 0xF7EEDC, text: 0x3A2E21, muted: 0x8A7962, accent: 0x8F5A2B)
        }
    }
}

// MARK: - Typeface and column

enum ComposerFont: String, CaseIterable, Identifiable {
    case serif
    case sans
    case mono
    case rounded

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .serif: "Serif"
        case .sans: "Sans"
        case .mono: "Mono"
        case .rounded: "Round"
        }
    }

    var swiftUIDesign: Font.Design {
        switch self {
        case .serif: .serif
        case .sans: .default
        case .mono: .monospaced
        case .rounded: .rounded
        }
    }

    func nsFont(size: CGFloat) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: .regular)
        let design: NSFontDescriptor.SystemDesign? = switch self {
        case .serif: .serif
        case .sans: nil
        case .mono: .monospaced
        case .rounded: .rounded
        }
        guard let design, let descriptor = base.fontDescriptor.withDesign(design) else { return base }
        return NSFont(descriptor: descriptor, size: size) ?? base
    }
}

enum ComposerColumn: String, CaseIterable, Identifiable {
    case narrow
    case comfortable
    case wide

    var id: String {
        rawValue
    }

    var title: String {
        rawValue.capitalized
    }

    var width: CGFloat {
        switch self {
        case .narrow: 560
        case .comfortable: 700
        case .wide: 880
        }
    }
}

// MARK: - Preferences

@MainActor
final class ComposerPreferences: ObservableObject {
    static let defaultFontSize = 19.0
    static let defaultLineHeight = 1.45

    @Published var theme: ComposerTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    @Published var font: ComposerFont {
        didSet { defaults.set(font.rawValue, forKey: Keys.font) }
    }

    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: Keys.fontSize) }
    }

    @Published var lineHeight: Double {
        didSet { defaults.set(lineHeight, forKey: Keys.lineHeight) }
    }

    @Published var column: ComposerColumn {
        didSet { defaults.set(column.rawValue, forKey: Keys.column) }
    }

    @Published var focusMode: Bool {
        didSet { defaults.set(focusMode, forKey: Keys.focusMode) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = ComposerTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .midnight
        font = ComposerFont(rawValue: defaults.string(forKey: Keys.font) ?? "") ?? .serif
        column = ComposerColumn(rawValue: defaults.string(forKey: Keys.column) ?? "") ?? .comfortable
        focusMode = defaults.bool(forKey: Keys.focusMode)

        let storedSize = defaults.double(forKey: Keys.fontSize)
        fontSize = storedSize == 0 ? Self.defaultFontSize : min(max(storedSize, 14), 34)

        let storedSpacing = defaults.double(forKey: Keys.lineHeight)
        lineHeight = storedSpacing == 0 ? Self.defaultLineHeight : min(max(storedSpacing, 1.1), 2.0)
    }

    func resetTypography() {
        font = .serif
        fontSize = Self.defaultFontSize
        lineHeight = Self.defaultLineHeight
        column = .comfortable
    }

    private enum Keys {
        static let theme = "verba.theme"
        static let font = "verba.font"
        static let fontSize = "verba.fontSize"
        static let lineHeight = "verba.lineHeight"
        static let column = "verba.column"
        static let focusMode = "verba.focusMode"
    }
}

// MARK: - Shared colors

extension Color {
    static let composerRecording = Color(red: 0.90, green: 0.28, blue: 0.30)
    static let composerWarning = Color(red: 0.95, green: 0.66, blue: 0.24)
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
