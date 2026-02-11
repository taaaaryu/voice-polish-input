#if swift(>=6.2) && canImport(Speech)
@preconcurrency import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechAnalyzerTranscriber: Transcriber {
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var capture: MicrophoneCapture?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?

    private var resultsTask: Task<Void, Never>?
    private var lastText: String = ""

    func start(
        onPartial: @escaping (String) -> Void,
        onFinal: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        lastText = ""

        resultsTask?.cancel()
        resultsTask = nil

        Task { @MainActor in
            do {
                try await startInternal(onPartial: onPartial, onFinal: onFinal)
            } catch {
                onError(error)
            }
        }
    }

    func stop() -> String {
        capture?.stop()
        inputContinuation?.finish()
        inputContinuation = nil

        Task { [analyzer] in
            do {
                try await analyzer?.finalizeAndFinishThroughEndOfInput()
            } catch {
                // Best-effort.
            }
        }

        resultsTask?.cancel()
        resultsTask = nil

        let out = lastText
        analyzer = nil
        transcriber = nil
        capture = nil
        return out
    }

    private func startInternal(
        onPartial: @escaping (String) -> Void,
        onFinal: @escaping (String) -> Void
    ) async throws {
        guard SpeechTranscriber.isAvailable else {
            throw NSError(domain: "VoicePolishInput", code: 10, userInfo: [
                NSLocalizedDescriptionKey: "SpeechTranscriber is not available on this device.",
            ])
        }

        let locale = Locale(identifier: "ja-JP")
        let supportedLocales = await SpeechTranscriber.supportedLocales
        guard supportedLocales.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) else {
            throw NSError(domain: "VoicePolishInput", code: 11, userInfo: [
                NSLocalizedDescriptionKey: "Unsupported locale: \(locale.identifier)",
            ])
        }

        for reserved in await AssetInventory.reservedLocales {
            await AssetInventory.release(reservedLocale: reserved)
        }
        try await AssetInventory.reserve(locale: locale)

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )
        self.transcriber = transcriber

        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }

        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw NSError(domain: "VoicePolishInput", code: 12, userInfo: [
                NSLocalizedDescriptionKey: "No compatible audio format for SpeechAnalyzer.",
            ])
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        let (inputSequence, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
        self.inputContinuation = continuation

        let capture = try MicrophoneCapture(targetFormat: format, inputContinuation: continuation)
        self.capture = capture
        try capture.start()

        // Start analyzer in background.
        Task.detached { [analyzer] in
            try await analyzer.start(inputSequence: inputSequence)
        }

        resultsTask = Task { @MainActor in
            var transcript = ""
            do {
                for try await result in transcriber.results {
                    let chunk = String(result.text.characters)
                    if chunk.isEmpty { continue }
                    transcript += chunk
                    lastText = transcript
                    onPartial(transcript)
                }
                onFinal(transcript)
            } catch {
                // Forward via stop() caller onError path.
            }
        }
    }
}

final class MicrophoneCapture: @unchecked Sendable {
    private let audioEngine: AVAudioEngine
    private let converter: AVAudioConverter
    private let inputContinuation: AsyncStream<AnalyzerInput>.Continuation
    private let targetFormat: AVAudioFormat

    init(targetFormat: AVAudioFormat, inputContinuation: AsyncStream<AnalyzerInput>.Continuation) throws {
        self.targetFormat = targetFormat
        self.inputContinuation = inputContinuation
        self.audioEngine = AVAudioEngine()

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0 else {
            throw NSError(domain: "VoicePolishInput", code: 20, userInfo: [
                NSLocalizedDescriptionKey: "Microphone permission denied.",
            ])
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw NSError(domain: "VoicePolishInput", code: 21, userInfo: [
                NSLocalizedDescriptionKey: "No compatible audio converter available.",
            ])
        }
        self.converter = converter

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [self] buffer, _ in
            handleBuffer(buffer)
        }
    }

    func start() throws {
        try audioEngine.start()
    }

    func stop() {
        audioEngine.stop()
        inputContinuation.finish()
    }

    private func handleBuffer(_ buffer: AVAudioPCMBuffer) {
        let frameCapacity = AVAudioFrameCount(
            ceil(Double(buffer.frameLength) * targetFormat.sampleRate / converter.inputFormat.sampleRate)
        )
        guard frameCapacity > 0 else { return }
        guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else { return }

        var error: NSError?
        nonisolated(unsafe) var consumed = false
        nonisolated(unsafe) let source = buffer
        converter.convert(to: converted, error: &error) { _, outStatus in
            if consumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return source
        }

        if error == nil, converted.frameLength > 0 {
            inputContinuation.yield(AnalyzerInput(buffer: converted))
        }
    }
}

#endif

