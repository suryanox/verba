import AppKit
import SwiftUI

@MainActor
final class MainWindowController: NSWindowController {
    init(model: ComposerViewModel) {
        let contentView = ComposerView(model: model)
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Verba"
        window.contentView = hostingView
        window.isRestorable = false
        window.identifier = nil
        window.restorationClass = nil
        window.center()
        super.init(window: window)
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
}
