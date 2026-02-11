import Foundation

@MainActor
final class TextPolisher {
    func polish(text: String, preferFoundationModels: Bool) async throws -> String {
        let rulePolished = RuleBasedPolisher.polish(text: text)
        guard preferFoundationModels else { return rulePolished }

        #if ENABLE_FOUNDATION_MODELS && canImport(FoundationModels)
        if let result = try await FoundationModelsPolisher.polishIfAvailable(text: rulePolished) {
            return result
        }
        #endif

        return rulePolished
    }
}

enum RuleBasedPolisher {
    static func polish(text: String) -> String {
        var t = text

        let fillers = [
            "えー", "え〜", "えぇ",
            "あの", "あのー", "あの〜",
            "えっと", "えっとー", "えっと〜",
            "その", "そのー", "その〜",
            "なんか",
        ]

        for f in fillers {
            t = t.replacingOccurrences(of: "\(f) ", with: "")
            t = t.replacingOccurrences(of: "\(f)　", with: "")
            t = t.replacingOccurrences(of: f, with: "")
        }

        while t.contains("  ") { t = t.replacingOccurrences(of: "  ", with: " ") }
        while t.contains("　　") { t = t.replacingOccurrences(of: "　　", with: "　") }

        t = t.replacingOccurrences(of: "、、", with: "、")
        t = t.replacingOccurrences(of: "。。", with: "。")

        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
