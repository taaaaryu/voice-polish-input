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

    @Published var useFoundationModelsWhenAvailable: Bool = false
    @Published var typeFallbackEnabled: Bool = true
    @Published var fillerWords: [String] = []
    @Published var replacementEntries: [UserReplacementEntry] = []
    @Published var historyEntries: [VoiceHistoryEntry] = []
    @Published var lastKeyDebugMessage: String = "No key event yet."

    private let hotKeyManager = HotKeyManager()
    private let keyCodeDebugMonitor = KeyCodeDebugMonitor()
    private let transcriber: Transcriber
    private let polisher = TextPolisher()
    private let injector = FocusedTextInjector()
    private let dictionaryStore = UserDictionaryStore()
    private var pendingInsertTarget: FocusedTextInjector.FocusTarget?

    init() {
        self.transcriber = DefaultTranscriberFactory.make()
        reloadDictionaryFromStore()

        hotKeyManager.onPress = { [weak self] in
            Task { @MainActor in self?.startRecordingIfNeeded() }
        }
        hotKeyManager.onRelease = { [weak self] in
            Task { @MainActor in self?.stopRecordingIfNeeded() }
        }
        hotKeyManager.isEnabled = isHotkeyEnabled

        keyCodeDebugMonitor.onEvent = { [weak self] message in
            Task { @MainActor in
                self?.lastKeyDebugMessage = message
            }
        }
        keyCodeDebugMonitor.start()
    }

    func toggleRecording() {
        lastError = nil

        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecordingIfNeeded() {
        guard !isRecording else { return }
        startRecording()
    }

    func stopRecordingIfNeeded() {
        guard isRecording else { return }
        stopRecording()
    }

    func insertFinalTextIntoFocusedField() {
        lastError = nil
        let text = finalText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        do {
            try injector.insert(text: text, allowTypeFallback: typeFallbackEnabled, target: pendingInsertTarget)
            pendingInsertTarget = nil
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
        reloadDictionaryFromStore()
        isRecording = true
        draftText = ""
        finalText = ""
        do {
            pendingInsertTarget = try injector.captureCurrentFocusTarget()
        } catch {
            pendingInsertTarget = nil
        }

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
        let rawFromEngine = transcriber.stop()
        let fallbackDraft = draftText
        let raw = rawFromEngine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallbackDraft : rawFromEngine

        Task { @MainActor in
            var inserted = false
            var errorMessage: String?
            var polishedOut = raw

            let rawTrimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !rawTrimmed.isEmpty else {
                let message = "No speech captured. Hold F13 while speaking and check microphone permission."
                lastError = message
                appendHistory(rawText: raw, polishedText: "", inserted: false, errorMessage: message)
                pendingInsertTarget = nil
                return
            }

            do {
                let polished = try await polisher.polish(
                    text: rawTrimmed,
                    preferFoundationModels: useFoundationModelsWhenAvailable,
                    fillerWords: fillerWords,
                    replacementEntries: replacementEntries
                )
                finalText = polished
                polishedOut = polished
                do {
                    try injector.insert(text: polished, allowTypeFallback: typeFallbackEnabled, target: pendingInsertTarget)
                    inserted = true
                } catch {
                    errorMessage = "Insert failed: \(error.localizedDescription)"
                    lastError = errorMessage
                }
            } catch {
                lastError = "Polish/insert failed: \(error.localizedDescription)"
                finalText = raw
                polishedOut = raw
                errorMessage = lastError
            }

            appendHistory(rawText: raw, polishedText: polishedOut, inserted: inserted, errorMessage: errorMessage)
            pendingInsertTarget = nil
        }
    }

    private func persistDictionary() {
        dictionaryStore.save(
            UserDictionaryData(
                fillerWords: fillerWords,
                replacementEntries: replacementEntries,
                historyEntries: historyEntries
            )
        )
    }

    private func appendHistory(rawText: String, polishedText: String, inserted: Bool, errorMessage: String?) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = VoiceHistoryEntry(
            id: UUID().uuidString,
            createdAtISO8601: timestamp,
            rawText: rawText,
            polishedText: polishedText,
            inserted: inserted,
            errorMessage: errorMessage
        )
        historyEntries.insert(entry, at: 0)
        if historyEntries.count > 300 {
            historyEntries.removeLast(historyEntries.count - 300)
        }
        persistDictionary()
    }

    private func reloadDictionaryFromStore() {
        let dictionaryData = dictionaryStore.load()
        fillerWords = dictionaryData.fillerWords
        replacementEntries = dictionaryData.replacementEntries
        historyEntries = dictionaryData.historyEntries
    }
}
