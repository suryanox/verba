import AppKit
import Combine
import SwiftUI

@MainActor
final class MainWindowController: NSWindowController {
    private var themeObservation: AnyCancellable?

    init(model: ComposerViewModel) {
        let preferences = ComposerPreferences()
        let contentView = ComposerView(model: model, preferences: preferences)
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: MainWindowController.defaultSize()),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Verba"
        window.contentView = hostingView
        window.isRestorable = false
        window.identifier = nil
        window.restorationClass = nil
        window.minSize = NSSize(width: 720, height: 520)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true

        // An empty unified toolbar makes the title bar taller, which centers the traffic lights
        // inside the 52pt header drawn by ComposerView.
        window.toolbar = NSToolbar(identifier: "VerbaToolbar")
        window.toolbarStyle = .unified

        window.center()
        super.init(window: window)

        style(window, for: preferences.theme)
        themeObservation = preferences.$theme.sink { [weak self] theme in
            guard let window = self?.window else { return }
            self?.style(window, for: theme)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// A comfortable size that scales with the screen but never fills it: about 70% of the width and 82% of
    /// the height, kept between 1000x740 and 1240x860.
    private static func defaultSize() -> NSSize {
        let screen = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1440, height: 900)
        return NSSize(
            width: min(max(screen.width * 0.7, 1000), 1240),
            height: min(max(screen.height * 0.82, 740), 860)
        )
    }

    func present() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func style(_ window: NSWindow, for theme: ComposerTheme) {
        window.backgroundColor = theme.nsBackground
        window.appearance = NSAppearance(named: theme.isDark ? .darkAqua : .aqua)
    }
}
