import AVFoundation
import Foundation

@MainActor
final class AVAudioRecorderService: NSObject, AudioRecorder {
    private var recorder: AVAudioRecorder?

    var isRecording: Bool {
        recorder?.isRecording == true
    }

    func start() throws {
        guard !isRecording else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("verba-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.prepareToRecord()
        guard recorder.record() else { throw AudioRecorderError.startFailed }
        self.recorder = recorder
    }

    func stop() throws -> URL {
        guard let recorder, recorder.isRecording else {
            throw AudioRecorderError.notRecording
        }
        let url = recorder.url
        recorder.stop()
        self.recorder = nil
        return url
    }
}

enum AudioRecorderError: Error, Equatable {
    case startFailed
    case notRecording
}
