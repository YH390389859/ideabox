import Foundation

/// Every partial result replaces only this session's words, keeping the existing draft intact.
struct SpeechInputDraft: Sendable {
    let originalText: String
    let characterLimit: Int

    init(originalText: String, characterLimit: Int = 4_000) {
        self.originalText = originalText
        self.characterLimit = max(0, characterLimit)
    }

    func merging(_ transcript: String) -> String {
        guard !transcript.isEmpty else { return originalText }
        let separator = originalText.isEmpty || originalText.last?.isWhitespace == true ? "" : "\n"
        let capacity = max(0, characterLimit - originalText.count - separator.count)
        guard capacity > 0 else { return originalText }
        return originalText + separator + transcript.prefix(capacity)
    }

    func wouldExceedLimit(_ transcript: String) -> Bool {
        guard !transcript.isEmpty else { return false }
        let separatorCount = originalText.isEmpty || originalText.last?.isWhitespace == true ? 0 : 1
        return originalText.count + separatorCount + transcript.count > characterLimit
    }
}
