import Foundation
import Speech

@MainActor
final class SpeechTranscriber: Transcriber {
    private let recognizer: SFSpeechRecognizer?

    init(locale: Locale = .current) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func transcribe(audio: URL) async throws -> String {
        guard let recognizer else { throw SpeechTranscriptionError.unavailable }
        guard recognizer.isAvailable else { throw SpeechTranscriptionError.unavailable }
        try await requestAuthorization()

        let request = SFSpeechURLRecognitionRequest(url: audio)
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result, result.isFinal else { return }
                continuation.resume(returning: result.bestTranscription.formattedString)
            }
        }
    }

    private func requestAuthorization() async throws {
        guard Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") != nil else {
            throw SpeechTranscriptionError.notAuthorized
        }

        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized { return }
        guard status == .notDetermined else {
            throw SpeechTranscriptionError.notAuthorized
        }

        let result = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard result == .authorized else {
            throw SpeechTranscriptionError.notAuthorized
        }
    }
}

enum SpeechTranscriptionError: Error, Equatable {
    case unavailable
    case notAuthorized
}
