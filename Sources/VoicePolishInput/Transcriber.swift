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
        // Legacy recognizer is used by default for lower start latency in push-to-talk.
        return LegacySFSpeechTranscriber()
    }
}
