import Foundation

@MainActor
final class ActivationCoordinator {
    private let shortcut: GlobalShortcutController
    private let focusedTargetProvider: FocusedTextTargetProvider

    var onTargetActivated: ((FocusedTextTarget) -> Void)?

    init(
        shortcut: GlobalShortcutController = GlobalShortcutController(),
        focusedTargetProvider: FocusedTextTargetProvider = FocusedTextTargetProvider()
    ) {
        self.shortcut = shortcut
        self.focusedTargetProvider = focusedTargetProvider
        shortcut.onActivation = { [weak self] in
            self?.handleActivation()
        }
    }

    func start() {
        shortcut.start()
    }

    func stop() {
        shortcut.stop()
    }

    private func handleActivation() {
        guard let target = focusedTargetProvider.focusedTarget() else { return }
        onTargetActivated?(target)
    }
}
