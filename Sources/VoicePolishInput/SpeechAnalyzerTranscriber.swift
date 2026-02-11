#if ENABLE_SPEECH_ANALYZER
import Foundation

final class SpeechAnalyzerTranscriber: Transcriber {
    func start(
        onPartial: @escaping (String) -> Void,
        onFinal: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        onError(NSError(domain: "VoicePolishInput", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "SpeechAnalyzer implementation requires macOS 26 SDK + Xcode 26",
        ]))
    }

    func stop() -> String {
        ""
    }
}
#endif

