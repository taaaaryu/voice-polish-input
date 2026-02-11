import AVFoundation
import Foundation
import Speech

@MainActor
final class LegacySFSpeechTranscriber: NSObject, Transcriber {
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var lastBest: String = ""

    private var onPartial: ((String) -> Void)?
    private var onFinal: ((String) -> Void)?
    private var onError: ((Error) -> Void)?

    func start(
        onPartial: @escaping (String) -> Void,
        onFinal: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onPartial = onPartial
        self.onFinal = onFinal
        self.onError = onError
        lastBest = ""

        Task { @MainActor in
            let status = await Self.requestAuthorizationStatus()
            self.handleAuthorization(status)
        }
    }

    func stop() -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        return lastBest
    }

    private func startEngine() throws {
        task?.cancel()
        task = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.onError?(error)
                    return
                }

                guard let result else { return }
                let text = result.bestTranscription.formattedString
                self.lastBest = text
                self.onPartial?(text)

                if result.isFinal {
                    self.onFinal?(text)
                }
            }
        }
    }

    private func handleAuthorization(_ status: SFSpeechRecognizerAuthorizationStatus) {
        guard status == .authorized else {
            onError?(NSError(domain: "VoicePolishInput", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Speech recognition not authorized (\(status.rawValue))",
            ]))
            return
        }

        do {
            try startEngine()
        } catch {
            onError?(error)
        }
    }

    private static func requestAuthorizationStatus() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
