import Foundation
import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

private final class MemoryAgentKey: AgentKeyStorage {
    var value = "test-only-key"
    func read() throws -> String { value }
    func write(_ key: String) throws { value = key }
    func remove() throws { value = "" }
}

@MainActor
private final class ScriptedAgentClient: AgentStreamingClient {
    enum Step {
        case response(AgentCompletion)
        case failure
        case partialThenFailure
        case waitForCancellation
    }
    var steps: [Step]
    var requests: [[AgentAPIMessage]] = []
    init(_ steps: [Step]) { self.steps = steps }

    func complete(apiKey: String, model: String, messages: [AgentAPIMessage], toolsData: Data?,
                  onText: @escaping @MainActor @Sendable (String) -> Void) async throws -> AgentCompletion {
        requests.append(messages)
        guard !steps.isEmpty else { throw URLError(.badServerResponse) }
        switch steps.removeFirst() {
        case .response(let completion):
            if let content = completion.message.content { onText(content) }
            return completion
        case .failure: throw URLError(.notConnectedToInternet)
        case .partialThenFailure:
            onText("正在整理，尚未保存")
            throw URLError(.networkConnectionLost)
        case .waitForCancellation:
            try await Task.sleep(for: .seconds(30))
            throw URLError(.timedOut)
        }
    }
}

@main @MainActor
struct AgentCoordinatorTests {
    static func expect(_ condition: @autoclosure () -> Bool, _ description: String) {
        precondition(condition(), description)
    }

    static func waitUntilIdle(_ coordinator: AgentCoordinator) async throws {
        for _ in 0..<500 {
            if !coordinator.isRunning { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        preconditionFailure("Coordinator did not stop")
    }

    static func response(_ content: String = "已记下。", calls: [AgentToolCall]? = nil) -> AgentCompletion {
        AgentCompletion(message: AgentAPIMessage(role: "assistant", content: content, toolCalls: calls),
                        finishReason: calls == nil ? "stop" : "tool_calls")
    }

    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("IdeaBox-AgentLoop-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let suite = "IdeaBox-AgentLoop-\(UUID())"
        let preferences = UserDefaults(suiteName: suite)!
        defer { preferences.removePersistentDomain(forName: suite) }
        let connection = AgentConnection(storage: MemoryAgentKey(), preferences: preferences)
        let model = AppModel(storageURL: root.appendingPathComponent("library.json"), seedSampleData: false)
        model.addHabit(name: "阅读", icon: .bookOpen, frequency: .daily)
        let diaryCall = AgentToolCall(id: "write-1", function: AgentFunctionCall(name: "create_diary", arguments: "{\"content\":\"留白也很重要。\",\"date\":\"\(Date().dayKey)\",\"tags\":[]}"))
        let habitCall = AgentToolCall(id: "habit-1", function: AgentFunctionCall(name: "set_habit_completion", arguments: "{\"habit_id\":\"\(model.habits[0].id)\",\"date\":\"\(Date().dayKey)\",\"completed\":true}"))
        let client = ScriptedAgentClient([.response(response("", calls: [diaryCall, habitCall])), .failure, .response(response())])
        let coordinator = AgentCoordinator(appModel: model, connection: connection, client: client)
        coordinator.send("阅读打卡完成，并记下：留白也很重要。")
        try await waitUntilIdle(coordinator)
        expect(model.diaries.count == 1, "One diary is persisted before the second HTTP round")
        expect(model.habits[0].isCompleted(on: Date()), "The habit is explicitly completed")
        expect(coordinator.needsRetry, "A network failure after a tool write offers continuation")
        expect(coordinator.receipts(for: coordinator.turns[0]).filter(\.success).count == 2, "Receipts survive a follow-up network failure")
        let secondRequest = client.requests[1]
        expect(secondRequest.filter { $0.role == "tool" }.count == 2, "Every tool call receives a real tool result")
        coordinator.retry()
        try await waitUntilIdle(coordinator)
        expect(model.diaries.count == 1 && model.habits[0].isCompleted(on: Date()), "Retry never duplicates or toggles prior writes")
        expect(coordinator.turns.last?.status == .completed, "The resumed reply completes")
        let stored = try String(contentsOf: coordinator.storageURL, encoding: .utf8)
        expect(!stored.contains("test-only-key"), "Secrets are never serialized into conversation history")
        let reloaded = AgentCoordinator(appModel: model, connection: connection, client: ScriptedAgentClient([]))
        expect(reloaded.turns.count == 1 && reloaded.receipts(for: reloaded.turns[0]).count == 2, "Conversation and receipt links survive a relaunch")
        let diaryReceipt = reloaded.receipts(for: reloaded.turns[0]).first { $0.kind == .diary }!
        reloaded.undo(diaryReceipt)
        expect(model.diaries.isEmpty, "Receipt undo uses the actual library transaction")
        expect(reloaded.receipts(for: reloaded.turns[0]).first { $0.id == diaryReceipt.id }?.undone == true, "The displayed receipt tracks authoritative undo state")

        let partialModel = AppModel(storageURL: root.appendingPathComponent("partial/library.json"), seedSampleData: false)
        let partial = AgentCoordinator(appModel: partialModel, connection: connection, client: ScriptedAgentClient([.partialThenFailure]))
        partial.send("记下今天的小事")
        try await waitUntilIdle(partial)
        expect(partialModel.diaries.isEmpty && partial.turns[0].receiptIDs.isEmpty, "An interrupted stream never creates a success receipt or business record")
        expect(partial.turns[0].messages.count == 1, "Incomplete assistant text does not enter API history")

        let cancelClient = ScriptedAgentClient([.waitForCancellation])
        let cancelled = AgentCoordinator(appModel: partialModel, connection: connection, client: cancelClient,
                                         storageURL: root.appendingPathComponent("cancelled.json"))
        cancelled.send("记下散步")
        while cancelClient.requests.isEmpty { await Task.yield() }
        cancelled.cancel()
        try await waitUntilIdle(cancelled)
        expect(cancelled.turns[0].status == .cancelled && partialModel.diaries.isEmpty, "Cancellation stops the stream without writing data")

        let corruptURL = root.appendingPathComponent("corrupt-conversation.json")
        let original = Data("{broken conversation".utf8)
        try original.write(to: corruptURL)
        let corrupt = AgentCoordinator(appModel: partialModel, connection: connection, client: ScriptedAgentClient([]), storageURL: corruptURL)
        corrupt.send("不得覆盖")
        expect(corrupt.turns.isEmpty, "Unreadable history blocks accidental replacement")
        let retained = try Data(contentsOf: corruptURL)
        expect(retained == original, "Unreadable original bytes are preserved")
        corrupt.clearConversation()
        expect(corrupt.errorMessage == nil, "Explicit new conversation safely recovers after backup")
        let backups = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        expect(backups.contains { $0.lastPathComponent.hasPrefix("corrupt-conversation.preserved-") }, "Recovery creates a backup of the original history")

        // Simulate termination in the narrow gap between the library transaction and conversation checkpoint.
        let crashModel = AppModel(storageURL: root.appendingPathComponent("crash/library.json"), seedSampleData: false)
        var crashTurn = AgentTurn(userText: "记下：留白也很重要。")
        crashTurn.messages = [AgentAPIMessage(role: "user", content: crashTurn.userText), response("", calls: [diaryCall]).message]
        let crashReceipt = crashModel.executeAgentTool(name: diaryCall.function.name, arguments: diaryCall.function.arguments,
                                                       operationID: "\(crashTurn.id):\(diaryCall.id)")
        expect(crashReceipt.success, "Crash fixture performs a durable tool transaction")
        let fixtureEncoder = JSONEncoder()
        fixtureEncoder.dateEncodingStrategy = .iso8601
        let turnData = try fixtureEncoder.encode([crashTurn])
        let fixture = Data("{\"schemaVersion\":1,\"turns\":".utf8) + turnData + Data("}".utf8)
        let crashHistoryURL = root.appendingPathComponent("crash/agent-conversation.json")
        try fixture.write(to: crashHistoryURL)
        let restartedModel = AppModel(storageURL: crashModel.storageURL, seedSampleData: false)
        let crashRecovery = AgentCoordinator(appModel: restartedModel, connection: connection,
                                             client: ScriptedAgentClient([.response(response())]))
        expect(crashRecovery.needsRetry, "A saved pending tool call is recoverable after restart")
        crashRecovery.retry()
        try await waitUntilIdle(crashRecovery)
        expect(restartedModel.diaries.count == 1, "A transaction checkpoint gap cannot duplicate the original diary")
        expect(crashRecovery.receipts(for: crashRecovery.turns[0]).count == 1, "Recovery reconnects the durable receipt to its original turn")

        // Starting a new message after that same interruption must also reveal already completed work.
        try fixture.write(to: crashHistoryURL)
        let newAfterCrash = AgentCoordinator(appModel: restartedModel, connection: connection,
                                             client: ScriptedAgentClient([.response(response("你好。"))]))
        newAfterCrash.send("你好")
        try await waitUntilIdle(newAfterCrash)
        expect(newAfterCrash.receipts(for: newAfterCrash.turns[0]).count == 1,
               "A new message preserves the real result of the preceding interrupted transaction")
        expect(restartedModel.diaries.count == 1, "Starting a new message does not re-execute the preceding write")

        let duplicateModel = AppModel(storageURL: root.appendingPathComponent("duplicate/library.json"), seedSampleData: false)
        var differentCall = diaryCall
        differentCall.function.arguments = "{\"content\":\"第二段原话\",\"date\":\"\(Date().dayKey)\",\"tags\":[]}"
        var uniqueCall = differentCall
        uniqueCall.id = "write-2"
        let duplicateClient = ScriptedAgentClient([
            .response(response("", calls: [diaryCall])), .response(response("", calls: [differentCall])),
            .response(response("", calls: [uniqueCall])), .response(response("两段都记下了。"))
        ])
        let duplicate = AgentCoordinator(appModel: duplicateModel, connection: connection, client: duplicateClient)
        duplicate.send("帮我分别保存两段原话")
        try await waitUntilIdle(duplicate)
        expect(duplicate.needsRetry && duplicateModel.diaries.count == 1,
               "A repeated cross-round tool ID pauses instead of silently omitting a new operation")
        expect(duplicate.turns[0].messages.flatMap { $0.toolCalls ?? [] }.count == 1,
               "The conflicting call never creates an unpaired protocol history entry")
        duplicate.retry()
        try await waitUntilIdle(duplicate)
        expect(duplicate.turns[0].status == .completed && duplicateModel.diaries.count == 2,
               "Retry with a fresh tool ID completes the outstanding action exactly once")
        print("PASS: real local multi-tool loop, retry deduplication, restart, undo, partial streams, cancellation, secret exclusion, and history recovery")
    }
}
