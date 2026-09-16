import Foundation

@main
struct AgentContextTests {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message) }
    static func json(_ value: [String: Any]) -> String {
        String(data: try! JSONSerialization.data(withJSONObject: value), encoding: .utf8)!
    }
    static func object(_ value: String) -> [String: Any] {
        try! JSONSerialization.jsonObject(with: Data(value.utf8)) as! [String: Any]
    }
    static func size(_ messages: [AgentAPIMessage]) -> Int { try! JSONEncoder().encode(messages).count }

    static func checkPairs(_ messages: [AgentAPIMessage]) {
        var pending = Set<String>()
        for message in messages {
            if message.role == "tool" {
                expect(message.toolCallID.map { pending.remove($0) != nil } == true, "Every tool result has a preceding call")
            } else {
                expect(pending.isEmpty, "No tool calls are left unanswered")
                if let calls = message.toolCalls { pending = Set(calls.map(\.id)) }
            }
        }
        expect(pending.isEmpty, "Final tool group is complete")
    }

    static func group(_ prefix: String, count: Int, arguments: String = "{}", result: String) -> [AgentAPIMessage] {
        let calls = (0..<count).map {
            AgentToolCall(id: "\(prefix)-\($0)", function: AgentFunctionCall(name: "search_records", arguments: arguments))
        }
        return [AgentAPIMessage(role: "assistant", content: nil, toolCalls: calls)] + calls.map {
            AgentAPIMessage(role: "tool", content: result, toolCallID: $0.id)
        }
    }

    static func main() {
        let unchanged = #"{"success":true,"operation_id":"same","undone":true}"#
        expect(AgentContext.toolResult(unchanged) == unchanged, "Small receipts are unchanged")
        let longText = String(repeating: "检索日常🧵", count: 400)
        let records = (0..<20).map { index in
            ["record_id": "record-\(index)", "kind": "diary", "date": "2026-09-15", "content": longText]
        }
        let raw = json(["success": true, "operation_id": "source-operation", "results": records, "limit": 20])
        let bounded = AgentContext.toolResult(raw)
        let value = object(bounded)
        expect(bounded.utf8.count <= 4_096, "Large search result fits four KB including metadata")
        expect(value["success"] as? Bool == true && value["operation_id"] as? String == "source-operation", "Actual outcome and ID survive")
        expect(value["truncated"] as? Bool == true && value["total_results"] as? Int == 20, "Omissions and original count are explicit")
        expect((value["results"] as? [Any])?.count == value["returned_results"] as? Int, "Returned count matches actual excerpt")
        expect(!bounded.contains("�"), "UTF-8 clipping does not create replacement characters")
        let created = object(AgentContext.toolResult(json(["success": true, "operation_id": "write-1", "record_id": "record-1", "content": longText])))
        expect(created["operation_id"] as? String == "write-1" && created["record_id"] as? String == "record-1", "Write identifiers are never shortened")
        expect(created["total_content_characters"] as? Int == longText.count, "Clipped diary text reports its full character count")
        let undo = object(AgentContext.toolResult(json(["success": true, "undone": true, "operation_id": "undo-1", "target_operation_id": "write-1", "content": longText])))
        expect(undo["undone"] as? Bool == true && undo["target_operation_id"] as? String == "write-1", "Undo state survives compression")
        for pathological in [
            json(["success": String(repeating: "x", count: 50_000)]),
            json(["success": true, "content": String(repeating: "\u{0001}", count: 8_000), "operation_id": "operation"]),
            json(["success": true, "operation_id": String(repeating: "标识", count: 4_000)])
        ] {
            let compressed = AgentContext.toolResult(pathological)
            expect(compressed.utf8.count <= 4_096, "Malformed field types and escaped control characters remain bounded")
            expect(object(compressed)["truncated"] as? Bool == true, "Exceptional omissions are disclosed")
        }

        let user = AgentAPIMessage(role: "user", content: "请找出这些线索，保留我的原话。")
        let searches = [user] + group("large", count: 32, result: raw)
        expect(size(searches) > 2_000_000, "Fixture reproduces the oversized read-results failure")
        let fixed = AgentContext.messages(system: "记录助手", turns: [searches])
        expect(size(fixed) < 600_000, "Thirty-two large search results now fit the request budget")
        expect(fixed.filter { $0.role == "tool" }.count == 32, "Normal bounded tool pairs remain available")
        expect(fixed[1] == user, "The original user text remains intact")
        checkPairs(fixed)

        let hugeArguments = json(["query": String(repeating: "长", count: 21_000)])
        let first = group("old", count: 10, arguments: hugeArguments, result: unchanged)
        let recent = group("recent", count: 1, result: unchanged)
        let pruned = AgentContext.messages(system: "记录助手", turns: [[user] + first + recent])
        expect(size(pruned) < 600_000, "An old completed group is dropped as a whole")
        expect(pruned.contains { $0.toolCalls?.first?.id == "recent-0" }, "The newest ordinary group is retained")
        expect(!pruned.contains { $0.toolCalls?.first?.id == "old-0" }, "Oversized older group is omitted")
        checkPairs(pruned)

        let singleHuge = AgentContext.messages(system: "记录助手", turns: [[user] + first])
        expect(size(singleHuge) < 600_000, "A single oversized completed group becomes a truthful summary")
        expect(singleHuge.dropFirst().first == user, "Original user survives single-group compression")
        expect(singleHuge.last?.content?.contains("search_records") == true, "Summary identifies the tools that actually ran")
        expect(singleHuge.last?.content?.contains("success") == true, "Summary carries actual tool outcomes")
        expect(singleHuge.allSatisfy { $0.toolCalls == nil && $0.toolCallID == nil }, "No partial arguments or orphan tool messages remain")
        checkPairs(singleHuge)

        let historical = (0..<15).map { index in
            [AgentAPIMessage(role: "user", content: "第\(index)轮"), AgentAPIMessage(role: "assistant", content: String(repeating: "答", count: 30_000))]
        }
        let history = AgentContext.messages(system: "记录助手", turns: historical + [[user] + recent])
        expect(size(history) < 600_000, "Older turns are dropped until their combined budget fits")
        expect(history.first?.content?.contains("完整对话回合未发送") == true, "Omitted prior turns are disclosed")
        expect(history.contains(user), "Current user survives old-turn pruning")
        checkPairs(history)

        var repeated = [user]
        for index in 0..<40 { repeated += group("many-\(index)", count: 32, result: raw) }
        let many = AgentContext.messages(system: "记录助手", turns: [repeated])
        expect(size(many) < 600_000, "A long resumed current turn remains bounded")
        checkPairs(many)
        expect(size(AgentContext.messages(system: String(repeating: "说明", count: 100_000), turns: [[user]])) < 600_000,
               "Unexpectedly large system context has a separate bound")
        print("PASS: bounded tool JSON, UTF-8, truthful omission metadata, 32 large searches, whole-turn pruning, complete tool groups, long resumed context")
    }
}
