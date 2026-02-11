import Foundation

struct UserReplacementEntry: Codable, Hashable {
    var from: String
    var to: String
}

struct VoiceHistoryEntry: Codable, Hashable, Identifiable {
    var id: String
    var createdAtISO8601: String
    var rawText: String
    var polishedText: String
    var inserted: Bool
    var errorMessage: String?
}

struct UserDictionaryData: Codable {
    var fillerWords: [String]
    var replacementEntries: [UserReplacementEntry]
    var historyEntries: [VoiceHistoryEntry]

    init(
        fillerWords: [String],
        replacementEntries: [UserReplacementEntry],
        historyEntries: [VoiceHistoryEntry]
    ) {
        self.fillerWords = fillerWords
        self.replacementEntries = replacementEntries
        self.historyEntries = historyEntries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fillerWords = try container.decodeIfPresent([String].self, forKey: .fillerWords) ?? []
        replacementEntries = try container.decodeIfPresent([UserReplacementEntry].self, forKey: .replacementEntries) ?? []
        historyEntries = try container.decodeIfPresent([VoiceHistoryEntry].self, forKey: .historyEntries) ?? []
    }
}

final class UserDictionaryStore {
    private let defaults = UserDefaults.standard
    private let legacyKey = "voice_polish_user_dictionary_v1"
    private let fileName = "state.json"

    private let defaultFillers = [
        "えー", "え〜", "えぇ",
        "あの", "あのー", "あの〜",
        "えっと", "えっとー", "えっと〜",
        "その", "そのー", "その〜",
        "なんか",
    ]

    func load() -> UserDictionaryData {
        if let raw = try? Data(contentsOf: stateFileURL()),
           let decoded = try? JSONDecoder().decode(UserDictionaryData.self, from: raw) {
            return decoded
        }

        if let legacyRaw = defaults.data(forKey: legacyKey),
           let legacyDecoded = try? JSONDecoder().decode(UserDictionaryData.self, from: legacyRaw) {
            save(legacyDecoded)
            return legacyDecoded
        }
        if let legacyRaw = defaults.data(forKey: legacyKey),
           let legacyDecoded = try? JSONDecoder().decode(LegacyDictionaryData.self, from: legacyRaw) {
            let migrated = UserDictionaryData(
                fillerWords: legacyDecoded.fillerWords,
                replacementEntries: legacyDecoded.replacementEntries,
                historyEntries: []
            )
            save(migrated)
            return migrated
        }

        let initial = defaultData()
        save(initial)
        return initial
    }

    func save(_ data: UserDictionaryData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            let fileURL = stateFileURL()
            let directoryURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try encoded.write(to: fileURL, options: .atomic)
            defaults.removeObject(forKey: legacyKey)
        } catch {
            // Best effort persistence.
        }
    }

    private func defaultData() -> UserDictionaryData {
        UserDictionaryData(
            fillerWords: defaultFillers,
            replacementEntries: [],
            historyEntries: []
        )
    }

    private func stateFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let base = appSupport ?? URL(fileURLWithPath: ("~/Library/Application Support" as NSString).expandingTildeInPath)
        return base
            .appendingPathComponent("VoicePolishInput", isDirectory: true)
            .appendingPathComponent(fileName)
    }
}

private struct LegacyDictionaryData: Codable {
    var fillerWords: [String]
    var replacementEntries: [UserReplacementEntry]
}
