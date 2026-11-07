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
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 720),
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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
