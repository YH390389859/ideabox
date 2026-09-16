import Foundation

/// Bounded copies for model context. The original receipts and conversation remain on disk.
enum AgentContext {
    private static let resultLimit = 4_096
    private static let requestLimit = 600_000

    static func toolResult(_ raw: String) -> String {
        guard let source = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else {
            return json(["truncated": true, "result_excerpt": prefix(raw, bytes: 1_500),
                         "truncation_note": "原始工具结果无法作为 JSON 读取，此处仅保留文字摘录。"])
        }
        if raw.utf8.count <= resultLimit { return raw }
        var result: [String: Any] = [:]
        for key in ["success", "operation_id", "target_operation_id", "record_id", "habit_id", "undone", "changed", "date", "completed", "limit"] {
            if let value = source[key] {
                if let text = value as? String { result[key] = text }
                else if value is NSNumber || value is NSNull { result[key] = value }
            }
        }
        for key in ["title", "url", "content", "excerpt", "error"] {
            if let value = source[key] as? String {
                result[key] = prefix(value, bytes: key == "content" || key == "excerpt" ? 768 : 400)
                if value != result[key] as? String { result["total_\(key)_characters"] = value.count }
            }
        }
        for key in ["results", "habits"] {
            if let values = source[key] as? [[String: Any]] {
                result["total_\(key)"] = values.count
                result[key] = values.prefix(8).map(compactRecord)
            }
        }
        result["truncated"] = true
        result["truncation_note"] = "为控制对话长度，部分文字和查询结果已省略；完整工具回执仍保存在本机。"
        for key in ["results", "habits"] {
            if let records = result[key] as? [[String: Any]] { result["returned_\(key)"] = records.count }
            while var records = result[key] as? [[String: Any]], !records.isEmpty,
                  json(result).utf8.count > resultLimit {
                records.removeLast()
                result[key] = records
                result["returned_\(key)"] = records.count
            }
        }
        if json(result).utf8.count > resultLimit {
            for key in ["content", "excerpt", "url", "title", "error"] {
                if let text = result[key] as? String { result[key] = prefix(text, bytes: 160) }
            }
        }
        // Never return a shortened identifier that could point at a different operation.
        if json(result).utf8.count > resultLimit {
            for key in ["title", "url", "content", "excerpt", "error", "date"] { result.removeValue(forKey: key) }
            for key in ["operation_id", "target_operation_id", "record_id", "habit_id"] where json(result).utf8.count > resultLimit {
                result.removeValue(forKey: key)
                result["identifiers_omitted"] = true
            }
        }
        let encoded = json(result)
        guard encoded.utf8.count > resultLimit else { return encoded }
        var fallback: [String: Any] = ["truncated": true, "identifiers_omitted": true,
                                      "truncation_note": "工具结果包含异常过长的字段，详细内容仅保留在本机。"]
        for key in ["success", "undone", "changed", "completed"] {
            if let value = source[key] as? Bool { fallback[key] = value }
        }
        return json(fallback)
    }

    static func messages(system: String, turns: [[AgentAPIMessage]]) -> [AgentAPIMessage] {
        var retained = Array(turns.suffix(12)).map { turn in
            turn.map { message in
                var copy = message
                if copy.role == "tool", let content = copy.content { copy.content = toolResult(content) }
                return copy
            }
        }
        var omittedTurns = max(0, turns.count - retained.count)
        var omittedGroups = 0
        var omittedTexts = 0
        let boundedSystem = prefix(system, bytes: 80_000)

        func assembled() -> [AgentAPIMessage] {
            var note = ""
            if omittedTurns > 0 { note += "\n[上下文说明：较早的 \(omittedTurns) 个完整对话回合未发送；请勿据此推测其内容。]" }
            if omittedGroups > 0 { note += "\n[上下文说明：当前回合的 \(omittedGroups) 组已完成工具调用已省略或压缩；不要因此重新执行。若有摘要，仅转述实际工具结果。]" }
            if omittedTexts > 0 { note += "\n[上下文说明：当前回合较早的 \(omittedTexts) 段助手文字已省略。]" }
            if boundedSystem != system { note += "\n[系统上下文过长，尾部资料已省略。]" }
            return [AgentAPIMessage(role: "system", content: boundedSystem + note)] + retained.flatMap { $0 }
        }

        while retained.count > 1, encodedSize(assembled()) > requestLimit {
            retained.removeFirst()
            omittedTurns += 1
        }
        guard !retained.isEmpty else { return assembled() }
        // A group consists of an assistant tool request and every matching tool response.
        // Replace whole completed groups only; never shorten JSON arguments or orphan a tool result.
        while encodedSize(assembled()) > requestLimit {
            guard let range = completedGroup(in: retained[0]) else { break }
            if completedGroup(in: Array(retained[0][range.upperBound...])) != nil {
                retained[0].removeSubrange(range)
            } else {
                let group = Array(retained[0][range])
                retained[0].replaceSubrange(range, with: [summary(of: group)])
            }
            omittedGroups += 1
        }
        // Unusually verbose prior text can also consume the budget; keep the original user message intact.
        if encodedSize(assembled()) > requestLimit {
            retained[0] = retained[0].map { message in
                guard message.role == "assistant", message.toolCalls?.isEmpty != false,
                      let content = message.content, content.utf8.count > 8_000 else { return message }
                var copy = message
                copy.content = prefix(content, bytes: 8_000) + "\n[较早的助手文字过长，后文已省略。]"
                return copy
            }
        }
        while encodedSize(assembled()) > requestLimit {
            guard let index = retained[0].indices.dropLast().first(where: {
                retained[0][$0].role == "assistant" && retained[0][$0].toolCalls?.isEmpty != false
            }) else { break }
            retained[0].remove(at: index)
            omittedTexts += 1
        }
        return assembled()
    }

    private static func compactRecord(_ source: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for key in ["kind", "record_id", "habit_id", "date", "scheduled", "completed", "name", "title", "schedule", "url", "content", "excerpt"] {
            guard let value = source[key] else { continue }
            if let text = value as? String {
                result[key] = prefix(text, bytes: key == "content" || key == "excerpt" ? 320 : 180)
            } else if value is NSNumber || value is NSNull { result[key] = value }
        }
        if let tags = source["tags"] as? [String] { result["tags"] = tags.prefix(4).map { prefix($0, bytes: 48) } }
        return result
    }

    private static func completedGroup(in messages: [AgentAPIMessage]) -> Range<Int>? {
        for index in messages.indices {
            let message = messages[index]
            guard message.role == "assistant", let calls = message.toolCalls, !calls.isEmpty else { continue }
            let expected = Set(calls.map(\.id))
            guard expected.count == calls.count else { continue }
            var answered = Set<String>()
            var end = index + 1
            while end < messages.count, messages[end].role == "tool" {
                if let id = messages[end].toolCallID, expected.contains(id) { answered.insert(id) }
                else { break }
                end += 1
            }
            if answered == expected { return index..<end }
        }
        return nil
    }

    private static func summary(of group: [AgentAPIMessage]) -> AgentAPIMessage {
        let names = Dictionary((group.first?.toolCalls ?? []).map { ($0.id, $0.function.name) }, uniquingKeysWith: { first, _ in first })
        let details = group.dropFirst().compactMap { message -> String? in
            guard let id = message.toolCallID, let name = names[id], let raw = message.content else { return nil }
            guard let value = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else {
                return "\(name)：结果无法读取，不能推定成功。"
            }
            var record: [String: Any] = ["tool": name]
            for key in ["success", "operation_id", "target_operation_id", "record_id", "habit_id", "undone", "changed", "completed", "date"] {
                if let field = value[key] { record[key] = field }
            }
            for key in ["title", "error"] {
                if let text = value[key] as? String { record[key] = prefix(text, bytes: 120) }
            }
            for key in ["results", "habits"] {
                if let values = value[key] as? [Any] {
                    record["returned_\(key)"] = values.count
                    record["total_\(key)"] = value["total_\(key)"] ?? values.count
                }
            }
            return json(record)
        }
        return AgentAPIMessage(role: "assistant", content: "[已完成工具调用的上下文摘要；详细参数和内容已省略，不应重新执行。]\n" + details.joined(separator: "\n"))
    }

    private static func encodedSize(_ messages: [AgentAPIMessage]) -> Int {
        (try? JSONEncoder().encode(messages).count) ?? Int.max
    }

    private static func prefix(_ text: String, bytes: Int) -> String {
        guard text.utf8.count > bytes else { return text }
        // String.Index remains on a scalar boundary even when a transport budget lands inside Chinese or emoji.
        var result = ""
        var used = 0
        for scalar in text.unicodeScalars {
            let size = scalar.utf8.count
            if used + size > bytes { break }
            result.unicodeScalars.append(scalar)
            used += size
        }
        return result
    }

    private static func json(_ value: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
