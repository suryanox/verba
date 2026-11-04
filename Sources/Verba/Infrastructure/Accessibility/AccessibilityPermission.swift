import ApplicationServices
import Foundation

@MainActor
struct AccessibilityPermission {
    func isTrusted(prompt: Bool = false) -> Bool {
        guard prompt else { return AXIsProcessTrusted() }

        guard Bundle.main.bundleURL.pathExtension == "app" else {
            print("Verba: Accessibility prompt skipped because this is not a packaged .app")
            return AXIsProcessTrusted()
        }

        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
