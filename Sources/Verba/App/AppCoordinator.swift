import Foundation

@MainActor
final class AppCoordinator {
    let session: VerbaSession

    init(session: VerbaSession = VerbaSession()) {
        self.session = session
    }
}
