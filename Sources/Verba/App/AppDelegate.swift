import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let composerModel = ComposerViewModel()
    private let permissions = PermissionCoordinator()
    private var mainWindow: MainWindowController?

    func applicationDidFinishLaunching(_: Notification) {
        AppMenu.install()
        permissions.requestAll()
        mainWindow = MainWindowController(model: composerModel)
        mainWindow?.present()
    }

    func applicationWillTerminate(_: Notification) {
        composerModel.flushDraft()
    }
}
