import Foundation

@MainActor
final class AppCoordinator {
    let session: VerbaSession
    let activation: ActivationCoordinator

    init(
        session: VerbaSession = VerbaSession(),
        activation: ActivationCoordinator = ActivationCoordinator()
    ) {
        self.session = session
        self.activation = activation
    }

    func start() {
        activation.start()
    }

    func stop() {
        activation.stop()
    }
}
