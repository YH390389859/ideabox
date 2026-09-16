import Foundation

private struct StubPlan: Sendable {
    var status = 200
    var contentType = "text/event-stream; charset=utf-8"
    var chunks: [Data] = []
    var waitForCancellation = false
}

private final class StubState: @unchecked Sendable {
    private let lock = NSLock()
    private var plan = StubPlan()
    private var requests: [URLRequest] = []

    func set(_ plan: StubPlan) { lock.withLock { self.plan = plan; requests = [] } }
    func start(_ request: URLRequest) -> StubPlan {
        lock.withLock { requests.append(request); return plan }
    }
    func lastRequest() -> URLRequest? { lock.withLock { requests.last } }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    static let state = StubState()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let plan = Self.state.start(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: plan.status, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": plan.contentType])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for chunk in plan.chunks { client?.urlProtocol(self, didLoad: chunk) }
        if !plan.waitForCancellation { client?.urlProtocolDidFinishLoading(self) }
    }
    override func stopLoading() {}
}

@main
struct AgentProtocolTests {
    static func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) {
        do { let result = try condition(); precondition(result, message) }
        catch { preconditionFailure("\(message): \(error)") }
    }

    static func expectThrows(_ expected: DeepSeekError, _ operation: () throws -> Void) {
        do { try operation(); preconditionFailure("Expected \(expected)") }
        catch { expect((error as? DeepSeekError) == expected, "Unexpected error: \(error)") }
    }

    static func event(_ delta: [String: Any] = [:], finish: String? = nil) -> String {
        let value: [String: Any] = ["choices": [["index": 0, "delta": delta, "finish_reason": finish as Any? ?? NSNull()]]]
        return String(data: try! JSONSerialization.data(withJSONObject: value), encoding: .utf8)!
    }

    static func stream(_ events: [String], crlf: Bool = false) -> Data {
        let separator = crlf ? "\r\n" : "\n"
        return Data(events.map { "data: \($0)\(separator)\(separator)" }.joined().utf8)
    }

    static var toolDefinitions: Data {
        Data(#"[{"type":"function","function":{"name":"create_diary","parameters":{"type":"object"}}},{"type":"function","function":{"name":"set_habit_completion","parameters":{"type":"object"}}}]"#.utf8)
    }

    static func toolStart(index: Int, id: String, name: String, arguments: String) -> [String: Any] {
        ["index": index, "id": id, "type": "function", "function": ["name": name, "arguments": arguments]]
    }

    static func protocolChecks() throws {
        var parser = AgentSSEParser()
        expect(try parser.append(line: ": keep-alive") == nil, "Comments do not create events")
        expect(try parser.append(line: "event: message") == nil, "Unknown fields are ignored")
        expect(try parser.append(line: "data: {\"text\":") == nil, "Multiline events stay buffered")
        expect(try parser.append(line: "data: \"中文🧵\"}") == nil, "Unicode stays intact")
        expect(try parser.append(line: "") == "{\"text\":\n\"中文🧵\"}", "Data lines join at blank delimiter")
        expect(try parser.append(line: "data:[DONE]") == nil, "Space after colon is optional")
        expect(parser.finish() == "[DONE]", "Final event is consumed at EOF")
        for newline in ["\n", "\r\n", "\r"] {
            var byteParser = AgentSSEByteParser()
            var parsed: [String] = []
            for byte in Data("\u{FEFF}: hello\(newline)data: 中文🧵\(newline)\(newline)".utf8) {
                if let event = try byteParser.append(byte: byte) { parsed.append(event) }
            }
            expect(parsed == ["中文🧵"], "Byte framing preserves all SSE line endings and optional BOM")
        }
        expectThrows(.invalidResponse) {
            var byteParser = AgentSSEByteParser()
            _ = try byteParser.append(byte: 0xFF)
            _ = try byteParser.append(byte: 10)
        }
        expectThrows(.tooLarge) {
            var byteParser = AgentSSEByteParser()
            for _ in 0...262_144 { _ = try byteParser.append(byte: 65) }
        }

        var plain = AgentStreamAccumulator()
        expect(try plain.append(event: event(["role": "assistant", "content": "今天"])) == "今天", "Text callback is a delta")
        expect(try plain.append(event: event(["content": "很棒🧵"])) == "很棒🧵", "Unicode text accumulates")
        _ = try plain.append(event: event(finish: "stop"))
        expectThrows(.incompleteStream) { _ = try plain.complete() }
        _ = try plain.append(event: "[DONE]")
        expect(try plain.complete().message.content == "今天很棒🧵", "DONE and finish reason both required")

        let names: Set<String> = ["create_diary", "set_habit_completion"]
        var tools = AgentStreamAccumulator(allowedToolNames: names)
        _ = try tools.append(event: event(["tool_calls": [
            toolStart(index: 1, id: "call_habit", name: "set_habit_completion", arguments: "{\"completed\":"),
            toolStart(index: 0, id: "call_diary", name: "create_diary", arguments: "{\"content\":\"今天")
        ]]))
        _ = try tools.append(event: event(["tool_calls": [
            ["index": 0, "function": ["arguments": "读书了🧵\"}"]],
            ["index": 1, "function": ["arguments": "true}"]]
        ]]))
        _ = try tools.append(event: event(finish: "tool_calls"))
        _ = try tools.append(event: "[DONE]")
        let completed = try tools.complete()
        expect(completed.message.content == nil, "Tool-only assistant content stays null")
        expect(completed.message.toolCalls?.map(\.id) == ["call_diary", "call_habit"], "Interleaved calls are ordered by index")
        expect(completed.message.toolCalls?[0].function.arguments == "{\"content\":\"今天读书了🧵\"}", "Tool JSON fragments concatenate")

        func invalidCall(_ calls: [[String: Any]], allowed: Set<String> = names,
                         reason: String = "tool_calls") -> () throws -> Void {
            return {
                var accumulator = AgentStreamAccumulator(allowedToolNames: allowed)
                _ = try accumulator.append(event: event(["tool_calls": calls], finish: reason))
                _ = try accumulator.append(event: "[DONE]")
                _ = try accumulator.complete()
            }
        }
        expectThrows(.invalidTool, invalidCall([
            toolStart(index: 0, id: "same", name: "create_diary", arguments: "{}"),
            toolStart(index: 1, id: "same", name: "set_habit_completion", arguments: "{}")
        ]))
        expectThrows(.invalidTool, invalidCall([toolStart(index: 0, id: "call", name: "unknown", arguments: "{}")]))
        expectThrows(.invalidTool, invalidCall([toolStart(index: 0, id: "call", name: "create_diary", arguments: "{\"content\":" )]))
        expectThrows(.invalidTool, invalidCall([toolStart(index: 0, id: "call", name: "create_diary", arguments: "[]")]))
        expectThrows(.invalidTool, invalidCall([toolStart(index: 0, id: "", name: "create_diary", arguments: "{}")]))
        expectThrows(.invalidTool, invalidCall([toolStart(index: 0, id: "call", name: "create_diary", arguments: "{}")], reason: "stop"))
        expectThrows(.tooLarge, invalidCall([toolStart(index: 32, id: "call", name: "create_diary", arguments: "{}")]))
        for reason in ["length", "content_filter", "aborted", "insufficient_system_resource"] {
            expectThrows(.incompleteStream) {
                var accumulator = AgentStreamAccumulator()
                _ = try accumulator.append(event: event(["content": "未完成"], finish: reason))
            }
        }
        expectThrows(.incompleteStream) {
            var accumulator = AgentStreamAccumulator()
            _ = try accumulator.append(event: "[DONE]")
        }
        expectThrows(.invalidResponse) {
            var accumulator = AgentStreamAccumulator()
            _ = try accumulator.append(event: "{\"error\":{\"message\":\"private secret\"}}")
        }
        expectThrows(.tooLarge) {
            var accumulator = AgentStreamAccumulator()
            _ = try accumulator.append(event: event(["content": String(repeating: "x", count: 131_073)]))
        }

        let message = AgentAPIMessage(role: "assistant", content: nil,
                                      toolCalls: [AgentToolCall(id: "call", function: AgentFunctionCall(name: "create_diary", arguments: "{}"))])
        let encoded = try JSONEncoder().encode(message)
        let object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        expect(object["content"] is NSNull && object["tool_calls"] != nil, "Wire keys and null content match API")
        expect(try JSONDecoder().decode(AgentAPIMessage.self, from: encoded) == message, "Protocol messages survive durable history")
        let tool = AgentAPIMessage(role: "tool", content: "{}", toolCallID: "call")
        let toolObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(tool)) as! [String: Any]
        expect(toolObject["tool_call_id"] as? String == "call", "Tool result is linked by wire key")
    }

    @MainActor
    static func networkChecks() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let client = DeepSeekClient(session: session)
        let messages = [AgentAPIMessage(role: "user", content: "记录今天")]
        let encoded = stream([event(["content": "已读到中文🧵"]), event(finish: "stop"), "[DONE]"], crlf: true)
        // Deliberately split UTF-8 scalars across transport chunks.
        StubURLProtocol.state.set(StubPlan(chunks: encoded.map { Data([$0]) }))
        var received = ""
        let completion = try await client.complete(apiKey: "test-key-only", model: "deepseek-flash", messages: messages,
                                                   toolsData: toolDefinitions, onText: { received += $0 })
        expect(received == "已读到中文🧵" && completion.message.content == received, "URLSession bytes preserves UTF-8 and SSE delimiters")
        let request = StubURLProtocol.state.lastRequest()!
        let bodyData: Data
        if let data = request.httpBody { bodyData = data }
        else if let input = request.httpBodyStream {
            input.open()
            defer { input.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while input.hasBytesAvailable {
                let count = input.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                data.append(contentsOf: buffer.prefix(count))
            }
            bodyData = data
        } else { preconditionFailure("Request body missing") }
        let body = try JSONSerialization.jsonObject(with: bodyData) as! [String: Any]
        expect(request.httpMethod == "POST", "SSE request supports POST")
        expect(body["stream"] as? Bool == true && body["max_tokens"] as? Int == 4096, "Streaming and output bounds sent")
        expect((body["thinking"] as? [String: String])?["type"] == "disabled", "Thinking explicitly disabled")
        expect((body["tools"] as? [Any])?.count == 2, "Tool definitions included")

        for status in [400, 401, 402, 422, 429, 500, 503] {
            StubURLProtocol.state.set(StubPlan(status: status, contentType: "application/json",
                                               chunks: [Data("{\"message\":\"test-key-only\"}".utf8)]))
            do {
                _ = try await client.complete(apiKey: "test-key-only", model: "deepseek-flash", messages: messages,
                                               toolsData: nil, onText: { _ in })
                preconditionFailure("HTTP failure accepted")
            } catch {
                expect((error as? DeepSeekError) == .http(status), "HTTP status preserved")
                expect(!error.localizedDescription.contains("test-key-only"), "Secret response text is never displayed")
            }
        }

        StubURLProtocol.state.set(StubPlan(chunks: [stream([event(["content": "截断"]), event(finish: "stop")])]))
        do {
            _ = try await client.complete(apiKey: "test-key-only", model: "deepseek-flash", messages: messages,
                                           toolsData: nil, onText: { _ in })
            preconditionFailure("Truncated response accepted")
        } catch { expect((error as? DeepSeekError) == .incompleteStream, "Transport EOF without DONE rejected") }

        StubURLProtocol.state.set(StubPlan(chunks: [stream([event(["content": "OK"], finish: "stop"), "[DONE]"])]))
        try await client.testConnection(apiKey: "test-key-only", model: "deepseek-flash")

        StubURLProtocol.state.set(StubPlan(waitForCancellation: true))
        let task = Task {
            try await client.complete(apiKey: "test-key-only", model: "deepseek-flash", messages: messages,
                                      toolsData: nil, onText: { _ in })
        }
        while StubURLProtocol.state.lastRequest() == nil { await Task.yield() }
        task.cancel()
        do { _ = try await task.value; preconditionFailure("Cancellation ignored") }
        catch { expect(error is CancellationError, "In-flight cancellation reaches URLSession") }
    }

    @MainActor
    static func main() async throws {
        try protocolChecks()
        try await networkChecks()
        print("PASS: SSE framing, Unicode, interleaved tools, malformed/truncated responses, HTTP failures, request contract, cancellation")
    }
}
