import Foundation

struct UserReplacementEntry: Codable, Hashable {
    var from: String
    var to: String
}

struct UserDictionaryData: Codable {
    var fillerWords: [String]
    var replacementEntries: [UserReplacementEntry]
}

final class UserDictionaryStore {
    private let defaults = UserDefaults.standard
    private let key = "voice_polish_user_dictionary_v1"

    private let defaultFillers = [
        "えー", "え〜", "えぇ",
        "あの", "あのー", "あの〜",
        "えっと", "えっとー", "えっと〜",
        "その", "そのー", "その〜",
        "なんか",
    ]

    func load() -> UserDictionaryData {
        guard let raw = defaults.data(forKey: key) else {
            return UserDictionaryData(
                fillerWords: defaultFillers,
                replacementEntries: []
            )
        }

        do {
            return try JSONDecoder().decode(UserDictionaryData.self, from: raw)
        } catch {
            return UserDictionaryData(
                fillerWords: defaultFillers,
                replacementEntries: []
            )
        }
    }

    func save(_ data: UserDictionaryData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: key)
        } catch {
            // Best effort persistence.
        }
    }
}

