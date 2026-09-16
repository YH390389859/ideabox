import Foundation

@main
struct SpeechInputTests {
    static func main() {
        let draft = SpeechInputDraft(originalText: "今天走了很多路。")
        precondition(draft.merging("还喝了") == "今天走了很多路。\n还喝了")
        precondition(draft.merging("还喝了一杯咖啡。") == "今天走了很多路。\n还喝了一杯咖啡。", "New partials replace old partials instead of repeating them")
        precondition(draft.merging("") == draft.originalText, "Cancellation or silence preserves the original draft exactly")
        precondition(SpeechInputDraft(originalText: "").merging("开口记录。") == "开口记录。")
        precondition(SpeechInputDraft(originalText: "已有草稿\n").merging("新的记录") == "已有草稿\n新的记录")
        precondition(SpeechInputDraft(originalText: "已有草稿 ").merging("新的记录") == "已有草稿 新的记录")

        let limited = SpeechInputDraft(originalText: "旧🧵", characterLimit: 5)
        precondition(limited.merging("新👨‍👩‍👧‍👦多余") == "旧🧵\n新👨‍👩‍👧‍👦", "The draft limit preserves complete Unicode graphemes")
        precondition(limited.wouldExceedLimit("新👨‍👩‍👧‍👦多余"))
        precondition(!limited.wouldExceedLimit("新👨‍👩‍👧‍👦"))
        let full = SpeechInputDraft(originalText: "已满", characterLimit: 2)
        precondition(full.merging("新增") == "已满", "Running out of room never deletes existing text")
        precondition(full.wouldExceedLimit("新增"))
        precondition(!full.wouldExceedLimit(""))
        let overfull = SpeechInputDraft(originalText: "原草稿已经超限", characterLimit: 2)
        precondition(overfull.merging("新增") == overfull.originalText)
        print("PASS: dictation partial replacement, draft preservation, spacing, Unicode character limits, full input")
    }
}
