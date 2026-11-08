import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private let model: OverlayViewModel
    private var panel: NSPanel?

    init(model: OverlayViewModel) {
        self.model = model
    }

    func show(near frame: CGRect?) {
        let panel = makePanelIfNeeded()
        let panelSize = panel.frame.size
        let origin: NSPoint

        if let frame {
            let screen = NSScreen.screens.first {
                $0.frame.contains(NSPoint(x: frame.midX, y: frame.midY))
            } ?? NSScreen.main
            let screenTop = screen?.frame.maxY ?? 0
            origin = NSPoint(
                x: frame.midX - panelSize.width / 2,
                y: screenTop - frame.minY + 8
            )
        } else {
            let screen = NSScreen.main?.visibleFrame ?? .zero
            origin = NSPoint(
                x: screen.midX - panelSize.width / 2,
                y: screen.midY - panelSize.height / 2
            )
        }
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 70),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.isRestorable = false
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(rootView: OverlayView(model: model))
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        self.panel = panel
        return panel
    }
}
