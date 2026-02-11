import Foundation
import XCTest
@testable import VoicePolishInput

final class VoicePolishInputTests: XCTestCase {
    func testResolvedRawTextUsesEngineWhenNotEmpty() {
        let resolved = VoicePolishController.resolvedRawText(
            rawFromEngine: "engine text",
            draftFallback: "draft text"
        )
        XCTAssertEqual(resolved, "engine text")
    }

    func testResolvedRawTextFallsBackToDraftWhenEngineIsWhitespace() {
        let resolved = VoicePolishController.resolvedRawText(
            rawFromEngine: "   ",
            draftFallback: "draft text"
        )
        XCTAssertEqual(resolved, "draft text")
    }

    func testRuleBasedPolisherAppliesFillersAndReplacement() {
        let output = RuleBasedPolisher.polish(
            text: "えー これは コーデックス です。。",
            fillerWords: ["えー"],
            replacementEntries: [
                UserReplacementEntry(from: "コーデックス", to: "Codex"),
            ]
        )
        XCTAssertEqual(output, "これは Codex です。")
    }

    func testUserDictionaryDataDecodingWithoutHistoryEntries() throws {
        let raw = """
        {
          "fillerWords": ["えー"],
          "replacementEntries": [{"from":"ジェミニ","to":"Gemini"}]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(UserDictionaryData.self, from: raw)
        XCTAssertEqual(decoded.fillerWords, ["えー"])
        XCTAssertEqual(decoded.replacementEntries.count, 1)
        XCTAssertTrue(decoded.historyEntries.isEmpty)
    }
}

