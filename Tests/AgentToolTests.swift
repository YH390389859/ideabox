import Foundation
import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

@main
struct AgentToolTests {
    static func expect(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message) }
    static func json(_ value: [String: Any]) -> String {
        String(data: try! JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]), encoding: .utf8)!
    }
    static func execute(_ model: AppModel, _ name: String, _ values: [String: Any], _ id: String) -> AgentToolReceipt {
        model.executeAgentTool(name: name, arguments: json(values), operationID: id)
    }

    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("IdeaBox-AgentTools-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("library.json")
        let model = AppModel(storageURL: url, seedSampleData: false)
        let today = Date().dayKey
        let yesterday = Calendar.ideabox.date(byAdding: .day, value: -1, to: Date())!.dayKey
        let diaryArgs: [String: Any] = ["content": "  留白，是为了让重要的事发生。\n原话。", "date": yesterday, "tags": [" 灵感 ", "灵感"]]
        let diary = execute(model, "create_diary", diaryArgs, "turn1:diary")
        expect(diary.success && diary.canUndo, "Created diary has a persisted undo receipt")
        expect(model.diaries.count == 1 && model.diaries[0].content == diaryArgs["content"] as? String, "Original diary wording is preserved")
        expect(model.diaries[0].dateAdded.dayKey == yesterday && model.diaries[0].mood == nil, "Historical date and unspecified mood are preserved")
        expect(model.diaries[0].tags == ["灵感"], "Tags are normalized")
        let reloaded = AppModel(storageURL: url, seedSampleData: false)
        expect(reloaded.canUndoAgentAction(operationID: diary.id), "Undo survives a disk roundtrip")
        expect(execute(reloaded, "create_diary", diaryArgs, diary.id).recordID == diary.recordID && reloaded.diaries.count == 1, "Retry after restart deduplicates")
        expect(!execute(reloaded, "create_diary", ["content": "Different", "date": today], diary.id).success, "A reused operation ID cannot mutate different arguments")
        let lookupBytes = try Data(contentsOf: url)
        let search = execute(reloaded, "search_records", ["query": "留白", "date": yesterday], "search1")
        expect(search.success && search.resultJSON.contains(diary.recordID!.uuidString), "Search finds the exact dated record")
        let afterLookupBytes = try Data(contentsOf: url)
        expect(afterLookupBytes == lookupBytes, "Read-only searches do not rewrite the library")
        reloaded.updateDiary(diary.recordID!, content: "后来我改过这句话")
        expect(!reloaded.canUndoAgentAction(operationID: diary.id) && !reloaded.undoAgentAction(operationID: diary.id).success, "Undo cannot delete a user-edited diary")
        reloaded.updateDiary(diary.recordID!, content: diaryArgs["content"] as! String)
        expect(!reloaded.undoAgentAction(operationID: diary.id).success, "Changing a record back cannot revive old undo authority")

        reloaded.addHabit(name: "阅读 30 分钟", icon: .bookOpen, frequency: .daily)
        let habitID = reloaded.habits[0].id
        let habitArgs: [String: Any] = ["habit_id": habitID.uuidString, "date": today, "completed": true]
        let completion = execute(reloaded, "set_habit_completion", habitArgs, "habit1")
        expect(completion.success && reloaded.habits[0].isCompleted(on: Date()), "Explicit habit state is applied")
        _ = execute(reloaded, "set_habit_completion", habitArgs, "habit1")
        expect(reloaded.habits[0].isCompleted(on: Date()), "Repeated check-in does not toggle state")
        let noOp = execute(reloaded, "set_habit_completion", habitArgs, "habit-no-op")
        expect(noOp.success && !noOp.canUndo, "An already-completed habit has no undo authority")
        reloaded.toggleHabit(habitID, on: AppFormatters.dayKey.date(from: yesterday)!)
        expect(reloaded.canUndoAgentAction(operationID: completion.id), "A different day's check-in does not invalidate undo")
        reloaded.toggleHabit(habitID, on: Date())
        reloaded.toggleHabit(habitID, on: Date())
        expect(!reloaded.undoAgentAction(operationID: completion.id).success, "Intervening same-day toggles invalidate older undo")
        expect(!execute(reloaded, "set_habit_completion", ["habit_id": habitID.uuidString, "date": today, "completed": 1], "numeric-bool").success, "Numeric 1 is not accepted as a boolean")
        reloaded.addHabit(name: "休息日测试", icon: .sun, frequency: .custom,
                          scheduledWeekdays: [Calendar.ideabox.component(.weekday, from: Date()) % 7 + 1])
        expect(!execute(reloaded, "set_habit_completion", ["habit_id": reloaded.habits[0].id.uuidString, "date": today, "completed": true], "rest-day").success, "Unscheduled check-ins are rejected")

        let clip = execute(reloaded, "save_clip", ["title": "灵感", "url": "https://example.com/path", "excerpt": "我的说明"], "clip1")
        let clipReload = AppModel(storageURL: url, seedSampleData: false)
        expect(clipReload.canUndoAgentAction(operationID: clip.id), "Clip undo snapshot survives timestamp serialization")
        let undo = execute(clipReload, "undo_action", ["operation_id": clip.id], "undo-clip1")
        expect(undo.success && undo.undone && clipReload.clips.isEmpty, "Conversational undo removes only its own new clip")
        expect(clipReload.agentReceipt(for: clip.id)?.undone == true, "Original receipt is marked undone")
        expect(execute(clipReload, "save_clip", ["title": "灵感", "url": "https://example.com/path", "excerpt": "我的说明"], "clip1").undone, "Retrying a previously undone operation does not recreate it")
        expect(execute(clipReload, "undo_action", ["operation_id": clip.id], "undo-clip1").success, "Undo itself is idempotent")
        let ownDiary = execute(clipReload, "create_diary", ["content": "可撤回", "date": today], "own-diary")
        expect(clipReload.libraryItems.first?.id == ownDiary.recordID, "Today's new diary sorts with the current timestamp")
        expect(abs(clipReload.diaries.first!.dateAdded.timeIntervalSinceNow) < 5, "Today's diary uses the current time rather than midnight")
        expect(clipReload.undoAgentAction(operationID: ownDiary.id).success, "Direct receipt undo works")
        expect(!clipReload.diaries.contains(where: { $0.id == ownDiary.recordID }), "Direct undo removes its record")
        expect(clipReload.undoAgentAction(operationID: ownDiary.id).undone, "Direct repeated undo is safe")

        let invalidCount = clipReload.collectionCount
        let future = Calendar.ideabox.date(byAdding: .day, value: 1, to: Date())!.dayKey
        for values: [String: Any] in [["content": "Future", "date": future], ["content": "Bad date", "date": "2026-02-30"],
                                      ["content": String(repeating: "a", count: 8_001), "date": today], ["content": "Unknown", "date": today, "mood": "happy"]] {
            expect(!execute(clipReload, "create_diary", values, UUID().uuidString).success, "Invalid diary input is rejected")
        }
        expect(!execute(clipReload, "save_clip", ["title": "local", "url": "file:///tmp/private"], "file-url").success, "Non-HTTP links are rejected")
        expect(!execute(clipReload, "save_clip", ["title": "bad", "url": "https://example.com/my page"], "space-url").success, "Whitespace in links is rejected")
        expect(!execute(clipReload, "save_clip", ["title": "bad", "url": "https://user:secret@example.com"], "credential-url").success, "Embedded URL credentials are rejected")
        expect(clipReload.collectionCount == invalidCount, "Rejected tools leave records untouched")
        expect(!clipReload.executeAgentTool(name: "create_diary", arguments: "{truncated", operationID: "bad-json").success, "Partial tool JSON never executes")
        expect(!execute(clipReload, "delete_all", [:], "unknown").success, "Unknown tools do not execute")

        // Force atomic save failure by replacing the library file with a nonempty directory.
        let beforeFailureCount = clipReload.diaries.count
        let beforeFailureOperations = clipReload.agentOperations.count
        let storedBytes = try Data(contentsOf: url)
        try FileManager.default.removeItem(at: url)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try Data([1]).write(to: url.appendingPathComponent("block"))
        let failed = execute(clipReload, "create_diary", ["content": "Must roll back", "date": today], "failed-save")
        expect(!failed.success && clipReload.diaries.count == beforeFailureCount && clipReload.agentOperations.count == beforeFailureOperations, "Persistence failure rolls back record and receipt journal together")
        expect(clipReload.agentReceipt(for: "failed-save") == nil, "Failed saves cannot produce a success receipt")
        try FileManager.default.removeItem(at: url)
        try storedBytes.write(to: url)
        expect(execute(clipReload, "create_diary", ["content": "Must roll back", "date": today], "failed-save").success, "The same operation can safely retry after a failed commit")

        let legacyURL = root.appendingPathComponent("legacy.json")
        let legacyData = Data(#"{"schemaVersion":1,"habits":[],"clips":[],"diaries":[]}"#.utf8)
        try legacyData.write(to: legacyURL)
        let legacy = AppModel(storageURL: legacyURL, seedSampleData: false)
        expect(legacy.agentReceipts.isEmpty && legacy.persistenceError == nil, "Schema1 loads with an empty journal")
        _ = execute(legacy, "create_diary", ["content": "Migrated", "date": today], "migration")
        let schema = try JSONSerialization.jsonObject(with: Data(contentsOf: legacyURL)) as! [String: Any]
        expect(schema["schemaVersion"] as? Int == 2 && schema["agentOperations"] != nil, "First write migrates to schema2 with the operation journal")
        let futureURL = root.appendingPathComponent("future.json")
        let futureBytes = Data(#"{"schemaVersion":99,"habits":false}"#.utf8)
        try futureBytes.write(to: futureURL)
        let futureModel = AppModel(storageURL: futureURL, seedSampleData: false)
        expect(!execute(futureModel, "create_diary", ["content": "No overwrite", "date": today], "future").success, "Future-schema libraries block agent writes")
        let finalFutureBytes = try Data(contentsOf: futureURL)
        expect(finalFutureBytes == futureBytes, "Future-schema original bytes remain intact")
        let definitions = try JSONSerialization.jsonObject(with: AgentToolCatalog.definitionsData) as! [[String: Any]]
        expect(definitions.count == 6, "All six native tools have parseable definitions")
        print("PASS: native tools, strict validation, original wording, dates, read-only search, atomic commit rollback, schema migration, durable deduplication and conflict-safe undo")
    }
}
