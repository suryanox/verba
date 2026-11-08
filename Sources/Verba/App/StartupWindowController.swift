import AppKit
import ApplicationServices
import AVFoundation
import Speech

@MainActor
final class StartupWindowController: NSWindowController {
    private let accessibilityStatus = NSTextField(labelWithString: "")
    private let microphoneStatus = NSTextField(labelWithString: "")
    private let speechStatus = NSTextField(labelWithString: "")
    private var refreshTimer: Timer?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 270),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Verba Setup"
        window.isRestorable = false
        window.identifier = nil
        window.restorationClass = nil
        window.center()
        super.init(window: window)
        configureContent()
        refresh()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh() {
        accessibilityStatus.stringValue = statusLine(
            "Accessibility",
            isGranted: AXIsProcessTrusted()
        )
        microphoneStatus.stringValue = statusLine(
            "Microphone",
            isGranted: AVAudioApplication.shared.recordPermission == .granted
        )
        speechStatus.stringValue = statusLine(
            "Speech recognition",
            isGranted: SFSpeechRecognizer.authorizationStatus() == .authorized
        )
    }

    func showWindow() {
        print("Verba: creating setup window")
        refresh()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        showWindow(nil)
        window?.level = .floating
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureContent() {
        let title = NSTextField(labelWithString: "Verba is running")
        title.font = .boldSystemFont(ofSize: 22)

        let description = NSTextField(
            wrappingLabelWithString: "Keep this window open while granting permissions. "
                + "Verba will show its microphone overlay near the focused text field."
        )

        let refreshButton = NSButton(
            title: "Refresh permissions",
            target: self,
            action: #selector(refreshPermissions)
        )
        let accessibilityButton = NSButton(
            title: "Open Accessibility Settings",
            target: self,
            action: #selector(openAccessibilitySettings)
        )
        let speechButton = NSButton(
            title: "Open Speech Settings",
            target: self,
            action: #selector(openSpeechSettings)
        )

        let stack = NSStackView(views: [
            title,
            description,
            accessibilityStatus,
            microphoneStatus,
            speechStatus,
            accessibilityButton,
            speechButton,
            refreshButton,
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        window?.contentView = contentView
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
        ])
    }

    @objc private func refreshPermissions() {
        refresh()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openSpeechSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    private func statusLine(_ name: String, isGranted: Bool) -> String {
        "\(isGranted ? "✓" : "○")  \(name): \(isGranted ? "Granted" : "Needs permission")"
    }
}
