import AVFoundation
import Speech

final class PermissionCoordinator {
    func requestAll() {
        AVAudioApplication.requestRecordPermission { granted in
            print("Verba: microphone permission = \(granted)")
        }
        guard Bundle.main.bundleURL.pathExtension == "app",
              Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") != nil else {
            print("Verba: speech permission skipped outside an app bundle")
            return
        }

        SFSpeechRecognizer.requestAuthorization { status in
            print("Verba: speech recognition permission = \(status == .authorized)")
        }
    }
}
