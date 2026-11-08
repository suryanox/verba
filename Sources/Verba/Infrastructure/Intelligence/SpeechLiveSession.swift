import AVFoundation
import Foundation
import Speech

private func makeAudioTap(for request: SFSpeechAudioBufferRecognitionRequest) -> AVAudioNodeTapBlock {
    { buffer, _ in
        request.append(buffer)
    }
}

@MainActor
final class SpeechLiveSession: LiveSpeechSession {
    private let recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var streamContinuation: AsyncStream<String>.Continuation?

    init(locale: Locale = .current) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func start() async throws -> AsyncStream<String> {
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechTranscriptionError.unavailable
        }
        try await requestAuthorization()

        stop()

        var continuation: AsyncStream<String>.Continuation?
        let stream = AsyncStream<String> { continuation = $0 }
        guard let continuation else { throw SpeechTranscriptionError.unavailable }
        streamContinuation = continuation

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format,
            block: makeAudioTap(for: request)
        )

        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                continuation.yield(result.bestTranscription.formattedString)
            }
            if error != nil {
                continuation.finish()
            }
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            recognitionTask?.cancel()
            recognitionTask = nil
            continuation.finish()
            throw error
        }

        audioEngine = engine
        recognitionRequest = request
        return stream
    }

    func stop() {
        finishAudioCapture()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        streamContinuation?.finish()
        streamContinuation = nil
        recognitionRequest = nil
        recognitionTask = nil
    }

    private func finishAudioCapture() {
        guard let engine = audioEngine else { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        audioEngine = nil
    }

    private func requestAuthorization() async throws {
        guard Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") != nil else {
            throw SpeechTranscriptionError.notAuthorized
        }

        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized {
            return
        }
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
