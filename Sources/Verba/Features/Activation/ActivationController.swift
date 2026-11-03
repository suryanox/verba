import Foundation

@MainActor
protocol ActivationController: AnyObject {
    var isEnabled: Bool { get }
    func start()
    func stop()
}
