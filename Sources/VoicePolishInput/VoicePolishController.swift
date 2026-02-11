import Foundation

@MainActor
final class VoicePolishController: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var draftText: String = ""
    @Published var finalText: String = ""
    @Published var lastError: String?

    @Published var isHotkeyEnabled: Bool = true {
        didSet { hotKeyManager.isEnabled = isHotkeyEnabled }
    }

    @Published var useFoundationModelsWhenAvailable: Bool = true
    @Published var typeFallbackEnabled: Bool = true

    private let hotKeyManager = HotKeyManager()
    private let transcriber: Transcriber
    private let polisher = TextPolisher()
    private let injector = FocusedTextInjector()

    init() {
        self.transcriber = DefaultTranscriberFactory.make()
        hotKeyManager.onToggle = { [weak self] in
            Task { @MainActor in self?.toggleRecording() }
        }
        hotKeyManager.isEnabled = isHotkeyEnabled
    }

    func toggleRecording() {
        lastError = nil

        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func insertFinalTextIntoFocusedField() {
        lastError = nil
        let text = finalText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        do {
            try injector.insert(text: text, allowTypeFallback: typeFallbackEnabled)
        } catch {
            lastError = "Insert failed: \(error.localizedDescription)"
        }
    }

    private func startRecording() {
        isRecording = true
        draftText = ""
        finalText = ""

        transcriber.start(
            onPartial: { [weak self] text in
                Task { @MainActor in self?.draftText = text }
            },
            onFinal: { [weak self] text in
                Task { @MainActor in self?.draftText = text }
            },
            onError: { [weak self] err in
                Task { @MainActor in
                    self?.lastError = "Transcribe failed: \(err.localizedDescription)"
                    self?.isRecording = false
                }
            }
        )
    }

    private func stopRecording() {
        isRecording = false
        let raw = transcriber.stop()

        Task { @MainActor in
            do {
                let polished = try await polisher.polish(
                    text: raw,
                    preferFoundationModels: useFoundationModelsWhenAvailable
                )
                finalText = polished
                try injector.insert(text: polished, allowTypeFallback: typeFallbackEnabled)
            } catch {
                lastError = "Polish/insert failed: \(error.localizedDescription)"
                finalText = raw
            }
        }
    }
}
