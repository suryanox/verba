import AppKit

@MainActor
enum SystemSettings {
    static func openSpeechRecognition() {
        let address = "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition"
        if let url = URL(string: address) {
            NSWorkspace.shared.open(url)
        }
    }
}
