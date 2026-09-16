import Foundation

struct AgentFunctionCall: Codable, Equatable, Sendable {
    var name: String
    var arguments: String
}

struct AgentToolCall: Codable, Equatable, Sendable {
    var id: String
    var type: String
    var function: AgentFunctionCall

    init(id: String, type: String = "function", function: AgentFunctionCall) {
        self.id = id
        self.type = type
        self.function = function
    }
}

struct AgentAPIMessage: Codable, Equatable, Sendable {
    var role: String
    var content: String?
    var toolCalls: [AgentToolCall]? = nil
    var toolCallID: String? = nil

    enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
        case toolCallID = "tool_call_id"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        if let content { try container.encode(content, forKey: .content) }
        else { try container.encodeNil(forKey: .content) }
        try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
        try container.encodeIfPresent(toolCallID, forKey: .toolCallID)
    }
}

struct AgentCompletion: Sendable {
    var message: AgentAPIMessage
    var finishReason: String
}

@MainActor
protocol AgentStreamingClient {
    func complete(apiKey: String, model: String, messages: [AgentAPIMessage], toolsData: Data?,
                  onText: @escaping @MainActor @Sendable (String) -> Void) async throws -> AgentCompletion
}

enum DeepSeekError: LocalizedError, Equatable {
    case invalidRequest, invalidResponse, incompleteStream, invalidTool, tooLarge, timeout, network
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRequest: "连接参数不完整，请检查模型名称和 API Key。"
        case .invalidResponse: "模型返回的内容暂时无法读取，请重试。"
        case .incompleteStream: "回复未完整送达，尚未执行的操作没有写入。可以继续重试。"
        case .invalidTool: "模型提出的操作参数不完整，尚未执行。请重试或换一种说法。"
        case .tooLarge: "这次回复或操作较多，请把内容分成小段后重试。"
        case .timeout: "DeepSeek 响应超时，请稍后重试。"
        case .network: "暂时无法连接 DeepSeek，请检查网络后重试。"
        case .http(401): "API Key 未通过验证，请检查连接设置中的密钥。"
        case .http(402): "DeepSeek 账户余额不足，请充值后重试。"
        case .http(429): "请求有些频繁，请稍后重试。"
        case .http(400), .http(422): "DeepSeek 未接受本次请求，请检查模型设置后重试。"
        case .http(500), .http(503): "DeepSeek 暂时繁忙，请稍后重试。"
        case .http: "DeepSeek 连接暂时不可用，请稍后重试。"
        }
    }
}

/// Framing is separate from the completion decoder so partial tool JSON is never executable.
struct AgentSSEParser {
    private var dataLines: [String] = []
    private var eventBytes = 0
    private var totalBytes = 0
    private let maximumBytes = 2_000_000

    mutating func append(line: String) throws -> String? {
        totalBytes += line.utf8.count
        guard totalBytes <= maximumBytes else { throw DeepSeekError.tooLarge }
        if line.isEmpty { return dispatch() }
        if line.hasPrefix(":") { return nil }
        let field: Substring
        var value: Substring
        if let separator = line.firstIndex(of: ":") {
            field = line[..<separator]
            value = line[line.index(after: separator)...]
            if value.first == " " { value = value.dropFirst() }
        } else {
            field = Substring(line)
            value = ""
        }
        guard field == "data" else { return nil }
        eventBytes += value.utf8.count
        guard eventBytes <= 262_144 else { throw DeepSeekError.tooLarge }
        dataLines.append(String(value))
        return nil
    }

    mutating func finish() -> String? { dispatch() }

    private mutating func dispatch() -> String? {
        guard !dataLines.isEmpty else { return nil }
        let event = dataLines.joined(separator: "\n")
        dataLines.removeAll(keepingCapacity: true)
        eventBytes = 0
        return event
    }
}

/// Foundation's AsyncBytes.lines skips empty lines, which are meaningful SSE delimiters.
/// Decode UTF-8 only after a complete bounded line, preserving CR, LF, and CRLF boundaries.
struct AgentSSEByteParser {
    private var parser = AgentSSEParser()
    private var line = Data()
    private var previousWasCR = false
    private var isFirstLine = true
    private var totalBytes = 0

    mutating func append(byte: UInt8) throws -> String? {
        totalBytes += 1
        guard totalBytes <= 2_000_000 else { throw DeepSeekError.tooLarge }
        if byte == 10, previousWasCR { previousWasCR = false; return nil }
        previousWasCR = byte == 13
        if byte == 10 || byte == 13 { return try dispatchLine() }
        line.append(byte)
        guard line.count <= 262_144 else { throw DeepSeekError.tooLarge }
        return nil
    }

    mutating func finish() throws -> String? {
        if !line.isEmpty, let event = try dispatchLine() { return event }
        return parser.finish()
    }

    private mutating func dispatchLine() throws -> String? {
        guard var text = String(data: line, encoding: .utf8) else { throw DeepSeekError.invalidResponse }
        line.removeAll(keepingCapacity: true)
        if isFirstLine, text.first == "\u{FEFF}" { text.removeFirst() }
        isFirstLine = false
        return try parser.append(line: text)
    }
}

struct AgentStreamAccumulator {
    private struct Chunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable {
                struct Tool: Decodable {
                    struct Function: Decodable { var name: String?; var arguments: String? }
                    var index: Int
                    var id: String?
                    var type: String?
                    var function: Function?
                }
                var content: String?
                var role: String?
                var tool_calls: [Tool]?
            }
            var index: Int
            var delta: Delta
            var finish_reason: String?
        }
        var choices: [Choice]
    }
    private struct PartialCall {
        var id = ""
        var name = ""
        var arguments = ""
    }

    private var content = ""
    private var calls: [Int: PartialCall] = [:]
    private var finishReason: String?
    private(set) var isDone = false
    private let allowedToolNames: Set<String>

    init(allowedToolNames: Set<String> = []) { self.allowedToolNames = allowedToolNames }

    /// Returns only visible text; arguments remain buffered until complete() validates all calls.
    mutating func append(event: String) throws -> String? {
        guard !isDone else { throw DeepSeekError.invalidResponse }
        if event.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
            guard finishReason != nil else { throw DeepSeekError.incompleteStream }
            isDone = true
            return nil
        }
        let chunk: Chunk
        do { chunk = try JSONDecoder().decode(Chunk.self, from: Data(event.utf8)) }
        catch { throw DeepSeekError.invalidResponse }
        // Some compatible servers send a final usage-only event.
        guard !chunk.choices.isEmpty else { return nil }
        guard chunk.choices.count == 1, let choice = chunk.choices.first, choice.index == 0 else {
            throw DeepSeekError.invalidResponse
        }
        if let role = choice.delta.role, role != "assistant" { throw DeepSeekError.invalidResponse }
        let fragment = choice.delta.content ?? ""
        let toolDeltas = choice.delta.tool_calls ?? []
        guard finishReason == nil || (fragment.isEmpty && toolDeltas.isEmpty) else {
            throw DeepSeekError.invalidResponse
        }
        content += fragment
        guard content.utf8.count <= 131_072 else { throw DeepSeekError.tooLarge }
        for delta in toolDeltas {
            guard (0..<32).contains(delta.index) else { throw DeepSeekError.tooLarge }
            guard delta.type == nil || delta.type == "function" else { throw DeepSeekError.invalidTool }
            var call = calls[delta.index] ?? PartialCall()
            if let id = delta.id {
                guard call.id.isEmpty || call.id == id else { throw DeepSeekError.invalidTool }
                call.id = id
            }
            if let name = delta.function?.name {
                guard call.name.isEmpty || call.name == name else { throw DeepSeekError.invalidTool }
                call.name = name
            }
            call.arguments += delta.function?.arguments ?? ""
            guard call.arguments.utf8.count <= 65_536, call.id.utf8.count <= 256,
                  call.name.utf8.count <= 128 else { throw DeepSeekError.tooLarge }
            calls[delta.index] = call
        }
        if let reason = choice.finish_reason {
            guard reason == "stop" || reason == "tool_calls" else { throw DeepSeekError.incompleteStream }
            guard finishReason == nil || finishReason == reason else { throw DeepSeekError.invalidResponse }
            finishReason = reason
        }
        return fragment.isEmpty ? nil : fragment
    }

    func complete() throws -> AgentCompletion {
        guard isDone, let finishReason else { throw DeepSeekError.incompleteStream }
        var ids = Set<String>()
        var toolCalls: [AgentToolCall] = []
        for index in calls.keys.sorted() {
            let call = calls[index]!
            guard !call.id.isEmpty, ids.insert(call.id).inserted,
                  allowedToolNames.contains(call.name),
                  let arguments = call.arguments.data(using: .utf8),
                  (try? JSONSerialization.jsonObject(with: arguments)) is [String: Any] else {
                throw DeepSeekError.invalidTool
            }
            toolCalls.append(AgentToolCall(id: call.id, function: AgentFunctionCall(name: call.name, arguments: call.arguments)))
        }
        guard (finishReason == "tool_calls") == !toolCalls.isEmpty else { throw DeepSeekError.invalidTool }
        guard !content.isEmpty || !toolCalls.isEmpty else { throw DeepSeekError.invalidResponse }
        return AgentCompletion(message: AgentAPIMessage(role: "assistant", content: content.isEmpty ? nil : content,
                                                        toolCalls: toolCalls.isEmpty ? nil : toolCalls),
                               finishReason: finishReason)
    }
}

@MainActor
final class DeepSeekClient: AgentStreamingClient {
    private let session: URLSession
    private let endpoint: URL

    init(session: URLSession = .shared, endpoint: URL = URL(string: "https://api.deepseek.com/chat/completions")!) {
        self.session = session
        self.endpoint = endpoint
    }

    func complete(apiKey: String, model: String, messages: [AgentAPIMessage], toolsData: Data?,
                  onText: @escaping @MainActor @Sendable (String) -> Void) async throws -> AgentCompletion {
        try await request(apiKey: apiKey, model: model, messages: messages, toolsData: toolsData,
                          maxTokens: 4096, onText: onText)
    }

    func testConnection(apiKey: String, model: String) async throws {
        _ = try await request(apiKey: apiKey, model: model,
                              messages: [AgentAPIMessage(role: "user", content: "Reply with exactly OK.")],
                              toolsData: nil, maxTokens: 64, onText: { _ in })
    }

    private func request(apiKey: String, model: String, messages: [AgentAPIMessage], toolsData: Data?,
                         maxTokens: Int, onText: @escaping @MainActor @Sendable (String) -> Void) async throws -> AgentCompletion {
        guard !apiKey.isEmpty, apiKey.utf8.count <= 512, !apiKey.contains(where: \.isWhitespace),
              !model.isEmpty, model.utf8.count <= 100, !messages.isEmpty else { throw DeepSeekError.invalidRequest }
        var body: [String: Any] = [
            "model": model, "messages": try JSONSerialization.jsonObject(with: JSONEncoder().encode(messages)),
            "thinking": ["type": "disabled"], "stream": true, "max_tokens": maxTokens, "temperature": 0.3
        ]
        var names = Set<String>()
        if let toolsData {
            guard let tools = try? JSONSerialization.jsonObject(with: toolsData) as? [[String: Any]],
                  !tools.isEmpty, tools.count <= 32 else { throw DeepSeekError.invalidRequest }
            for tool in tools {
                guard tool["type"] as? String == "function", let function = tool["function"] as? [String: Any],
                      let name = function["name"] as? String, !name.isEmpty,
                      names.insert(name).inserted else { throw DeepSeekError.invalidRequest }
            }
            body["tools"] = tools
            body["tool_choice"] = "auto"
        }
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        guard bodyData.count <= 2_000_000 else { throw DeepSeekError.tooLarge }
        var request = URLRequest(url: endpoint, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = bodyData
        var parser = AgentSSEByteParser()
        var accumulator = AgentStreamAccumulator(allowedToolNames: names)
        do {
            try Task.checkCancellation()
            let (bytes, response) = try await session.bytes(for: request)
            defer { bytes.task.cancel() }
            guard let response = response as? HTTPURLResponse else { throw DeepSeekError.invalidResponse }
            guard (200..<300).contains(response.statusCode) else { throw DeepSeekError.http(response.statusCode) }
            guard response.value(forHTTPHeaderField: "Content-Type")?.lowercased().contains("text/event-stream") == true else {
                throw DeepSeekError.invalidResponse
            }
            for try await byte in bytes {
                try Task.checkCancellation()
                if let event = try parser.append(byte: byte) {
                    if let fragment = try accumulator.append(event: event) { onText(fragment) }
                    if accumulator.isDone { break }
                }
            }
            if !accumulator.isDone, let event = try parser.finish() {
                if let fragment = try accumulator.append(event: event) { onText(fragment) }
            }
            try Task.checkCancellation()
            return try accumulator.complete()
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if Task.isCancelled || error.code == .cancelled { throw CancellationError() }
            throw error.code == .timedOut ? DeepSeekError.timeout : DeepSeekError.network
        } catch let error as DeepSeekError {
            throw error
        } catch {
            throw DeepSeekError.invalidResponse
        }
    }
}
