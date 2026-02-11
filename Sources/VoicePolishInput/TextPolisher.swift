import Foundation

@MainActor
final class TextPolisher {
    func polish(
        text: String,
        preferFoundationModels: Bool,
        fillerWords: [String],
        replacementEntries: [UserReplacementEntry]
    ) async throws -> String {
        let rulePolished = RuleBasedPolisher.polish(
            text: text,
            fillerWords: fillerWords,
            replacementEntries: replacementEntries
        )
        guard preferFoundationModels else { return rulePolished }

        #if swift(>=6.2) && canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            if let result = try await FoundationModelsPolisher.polishIfAvailable(text: rulePolished) {
                return result
            }
        }
        #endif

        return rulePolished
    }
}

enum RuleBasedPolisher {
    static func polish(
        text: String,
        fillerWords: [String],
        replacementEntries: [UserReplacementEntry]
    ) -> String {
        var t = text

        for f in fillerWords {
            t = t.replacingOccurrences(of: "\(f) ", with: "")
            t = t.replacingOccurrences(of: "\(f)　", with: "")
            t = t.replacingOccurrences(of: f, with: "")
        }

        for entry in replacementEntries {
            t = t.replacingOccurrences(of: entry.from, with: entry.to)
        }

        while t.contains("  ") { t = t.replacingOccurrences(of: "  ", with: " ") }
        while t.contains("　　") { t = t.replacingOccurrences(of: "　　", with: "　") }

        t = t.replacingOccurrences(of: "、、", with: "、")
        t = t.replacingOccurrences(of: "。。", with: "。")

        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
