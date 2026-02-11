import Foundation

@MainActor
protocol Transcriber {
    func start(
        onPartial: @escaping (String) -> Void,
        onFinal: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    )

    func stop() -> String
}

enum DefaultTranscriberFactory {
    @MainActor
    static func make() -> Transcriber {
        #if ENABLE_SPEECH_ANALYZER
        return SpeechAnalyzerTranscriber()
        #else
        return LegacySFSpeechTranscriber()
        #endif
    }
}
