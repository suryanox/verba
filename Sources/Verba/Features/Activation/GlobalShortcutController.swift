import AppKit

@MainActor
final class GlobalShortcutController: ActivationController {
    private let configuration: ShortcutConfiguration
    private var monitors: [Any] = []

    var isEnabled: Bool { !monitors.isEmpty }
    var onActivation: (() -> Void)?

    init(configuration: ShortcutConfiguration = .default) {
        self.configuration = configuration
    }

    func start() {
        guard !isEnabled else { return }

        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                guard self.configuration.matches(event) else { return }
                self.onActivation?()
            }
        }

        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.configuration.matches(event) else { return event }
            self.onActivation?()
            return nil
        }

        monitors = [globalMonitor, localMonitor].compactMap { $0 }
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }

}
