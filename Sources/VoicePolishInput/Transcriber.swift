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
        #if swift(>=6.2) && canImport(Speech)
        if #available(macOS 26.0, *) {
            return SpeechAnalyzerTranscriber()
        }
        return LegacySFSpeechTranscriber()
        #else
        return LegacySFSpeechTranscriber()
        #endif
    }
}
