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
    @Published var fillerWords: [String] = []
    @Published var replacementEntries: [UserReplacementEntry] = []

    private let hotKeyManager = HotKeyManager()
    private let transcriber: Transcriber
    private let polisher = TextPolisher()
    private let injector = FocusedTextInjector()
    private let dictionaryStore = UserDictionaryStore()

    init() {
        self.transcriber = DefaultTranscriberFactory.make()
        let dictionaryData = dictionaryStore.load()
        fillerWords = dictionaryData.fillerWords
        replacementEntries = dictionaryData.replacementEntries

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

    func addFillerWord(_ rawWord: String) {
        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return }
        guard !fillerWords.contains(word) else { return }
        fillerWords.append(word)
        fillerWords.sort()
        persistDictionary()
    }

    func removeFillerWord(_ word: String) {
        fillerWords.removeAll { $0 == word }
        persistDictionary()
    }

    func addReplacement(from rawFrom: String, to rawTo: String) {
        let from = rawFrom.trimmingCharacters(in: .whitespacesAndNewlines)
        let to = rawTo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !from.isEmpty, !to.isEmpty else { return }

        if let idx = replacementEntries.firstIndex(where: { $0.from == from }) {
            replacementEntries[idx] = UserReplacementEntry(from: from, to: to)
        } else {
            replacementEntries.append(UserReplacementEntry(from: from, to: to))
        }

        replacementEntries.sort { $0.from < $1.from }
        persistDictionary()
    }

    func removeReplacement(from: String) {
        replacementEntries.removeAll { $0.from == from }
        persistDictionary()
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
                    preferFoundationModels: useFoundationModelsWhenAvailable,
                    fillerWords: fillerWords,
                    replacementEntries: replacementEntries
                )
                finalText = polished
                try injector.insert(text: polished, allowTypeFallback: typeFallbackEnabled)
            } catch {
                lastError = "Polish/insert failed: \(error.localizedDescription)"
                finalText = raw
            }
        }
    }

    private func persistDictionary() {
        dictionaryStore.save(
            UserDictionaryData(
                fillerWords: fillerWords,
                replacementEntries: replacementEntries
            )
        )
    }
}
