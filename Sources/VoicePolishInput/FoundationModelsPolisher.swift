#if swift(>=6.2) && canImport(FoundationModels)
import Foundation
import FoundationModels

@MainActor
enum FoundationModelsPolisher {
    static func polishIfAvailable(text: String) async throws -> String? {
        guard SystemLanguageModel.default.isAvailable else { return nil }

        let session = LanguageModelSession(model: SystemLanguageModel.default)

        let prompt = """
        次の文章を、意味を変えずに、自然で読みやすい日本語に整形してください。
        ルール:
        - 内容の追加・削除は禁止（言い換えは最小限）
        - フィラー（えー、あの、えっと等）は削除
        - 句読点を適切に補い、読みやすい改行にする

        文章:
        \(text)
        """

        let response = try await session.respond(to: prompt)
        let out = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return out.isEmpty ? nil : out
    }
}
#endif
