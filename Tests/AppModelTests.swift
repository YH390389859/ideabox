import Foundation
import SwiftUI

// Standalone model checks; compile together with IdeaBox/AppModel.swift for macOS.
// This file is outside the iOS target's source folder.
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

@main
struct AppModelTests {
    static func expect(_ value: @autoclosure () -> Bool, _ message: String) {
        precondition(value(), message)
    }

    static func date(_ key: String) -> Date { AppFormatters.dayKey.date(from: key)! }

    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("IdeaBox-Tests-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let daily = Habit(id: UUID(), name: "Daily", icon: .bookOpen,
                          completedDates: ["2026-09-01", "2026-09-03", "2026-09-04", "2026-09-05", "2026-09-08"], frequency: .daily)
        expect(daily.streak(endingOn: date("2026-09-06")) == 3, "Today has grace; unrelated/future dates cannot extend a streak")
        expect(daily.streak(endingOn: date("2026-09-07")) == 0, "Missing yesterday breaks the streak")
        expect(daily.streak(endingOn: date("2026-09-05")) == 3, "Completed today is included")
        let weekday = Habit(id: UUID(), name: "Weekday", icon: .bookOpen,
                            completedDates: ["2026-09-03", "2026-09-04"], frequency: .weekday)
        expect(weekday.streak(endingOn: date("2026-09-07")) == 2, "Rest days do not break a streak")
        expect(!weekday.isScheduled(on: date("2026-09-06")), "Weekdays skip Sunday")
        let weekly = Habit(id: UUID(), name: "Weekly", icon: .sun,
                           completedDates: ["2026-08-23", "2026-08-30"], frequency: .weekly)
        expect(weekly.streak(endingOn: date("2026-09-06")) == 2, "Weekly streak counts consecutive scheduled Sundays")
        expect(weekly.streak(endingOn: date("2026-09-07")) == 0, "An unfinished scheduled Sunday breaks the streak on Monday")
        let custom = Habit(id: UUID(), name: "Custom", icon: .sun, completedDates: [], frequency: .custom, scheduledWeekdays: [2, 8])
        expect(custom.activeWeekdays == [2], "Invalid weekdays are ignored")
        expect(custom.isScheduled(on: date("2026-09-07")), "Custom Monday schedule works")

        let url = root.appendingPathComponent("library.json")
        let model = AppModel(storageURL: url, seedSampleData: false)
        expect(model.currentTab == .dashboard, "Default page is dashboard")
        expect(model.habits.isEmpty && model.collectionCount == 0, "Empty initialization can be requested")
        model.addHabit(name: "  Read  ", icon: .bookOpen, frequency: .daily)
        let habitID = model.habits[0].id
        model.toggleHabit(habitID, on: Date())
        model.addClip(title: "Link", url: "https://example.com", excerpt: "A saved link", tags: ["Design", "Design", "  Art "])
        model.addDiary(type: .text, content: "A thought", richTextData: Data([1, 2, 3]), tags: ["Work"])
        let diaryID = model.diaries[0].id
        expect(model.totalCheckIns == 1 && model.completionRate(on: Date()) == 1, "Completion statistics match the schedule")
        let reload = AppModel(storageURL: url)
        expect(reload.habits.count == 1 && reload.habits[0].id == habitID, "Habits are restored instead of reseeded")
        expect(reload.habits[0].name == "Read" && reload.habits[0].completedDates.contains(Date().dayKey), "Names and check-ins survive a relaunch")
        expect(reload.diaries[0].richTextData == Data([1, 2, 3]), "Rich text bytes survive JSON encoding")
        expect(reload.clips[0].tags == ["Design", "Art"], "Tags are trimmed and deduplicated")
        reload.updateHabit(habitID, name: "Read more", icon: .brain, frequency: .weekday)
        reload.updateDiary(diaryID, content: "Edited thought", tags: ["Ideas"])
        reload.updateClip(reload.clips[0].id, title: "Edited link", url: "https://example.org", excerpt: "Updated")
        let edited = AppModel(storageURL: url)
        expect(edited.habits[0].name == "Read more" && edited.diaries[0].content == "Edited thought", "Updates persist")
        expect(edited.clips[0].url == "https://example.org", "Clip edits persist")
        edited.deleteHabit(habitID)
        edited.deleteClip(edited.clips[0].id)
        edited.deleteDiary(diaryID)
        let emptyReload = AppModel(storageURL: url)
        expect(emptyReload.habits.isEmpty && emptyReload.collectionCount == 0, "Deleted data stays deleted; empty libraries are never reseeded")

        let oldDiary = #"{"id":"00112233-4455-6677-8899-AABBCCDDEEFF","type":"text","content":"Legacy","richTextData":null,"duration":null,"mood":null,"tags":[],"dateAdded":"2026-09-06T00:00:00Z"}"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let legacy = try decoder.decode(DiaryEntry.self, from: Data(oldDiary.utf8))
        expect(legacy.audioFileName == nil, "Pre-audio diary records decode without migration")
        let oldHabit = #"{"id":"00112233-4455-6677-8899-AABBCCDDEEFF","name":"Legacy","icon":"BookOpen","completedDates":[],"frequency":"daily"}"#
        let legacyHabit = try decoder.decode(Habit.self, from: Data(oldHabit.utf8))
        expect(legacyHabit.scheduledWeekdays == nil, "Pre-schedule habit records decode without migration")

        let corruptURL = root.appendingPathComponent("corrupt.json")
        let originalBytes = Data("{truncated json".utf8)
        try originalBytes.write(to: corruptURL)
        let recovered = AppModel(storageURL: corruptURL)
        expect(recovered.collectionCount == 0 && recovered.habits.isEmpty, "Corruption recovery does not replace user records with samples")
        expect(recovered.recoveredBackupURL != nil, "Corrupt libraries have a discoverable backup")
        let backupBytes = try Data(contentsOf: recovered.recoveredBackupURL!)
        expect(backupBytes == originalBytes, "Backup preserves all original bytes")
        recovered.addDiary(type: .text, content: "Recovered")
        expect(AppModel(storageURL: corruptURL).diaries[0].content == "Recovered", "Library is usable after preserving corruption")

        let futureURL = root.appendingPathComponent("future.json")
        let futureBytes = Data(#"{"schemaVersion":99,"habits":[],"clips":[],"diaries":[]}"#.utf8)
        try futureBytes.write(to: futureURL)
        let future = AppModel(storageURL: futureURL)
        future.addDiary(type: .text, content: "Must not overwrite")
        expect(future.persistenceError != nil, "Unsupported formats expose an error")
        let unchangedFutureBytes = try Data(contentsOf: futureURL)
        expect(unchangedFutureBytes == futureBytes, "Unsupported formats remain untouched")

        let incompatibleURL = root.appendingPathComponent("future-incompatible.json")
        let incompatibleBytes = Data(#"{"schemaVersion":99,"habits":{"entries":[]},"clips":false,"diaries":[{"type":"sketch","canvas":{"layers":[]}}]}"#.utf8)
        try incompatibleBytes.write(to: incompatibleURL)
        let incompatible = AppModel(storageURL: incompatibleURL)
        expect(incompatible.persistenceError != nil, "Future schemas are detected before decoding incompatible record structures")
        expect(incompatible.recoveredBackupURL == nil, "An incompatible future schema is not treated as a corrupt library")
        incompatible.addDiary(type: .text, content: "Must not replace a newer schema")
        expect(!incompatible.save(), "A newer schema keeps persistence disabled")
        let unchangedIncompatibleBytes = try Data(contentsOf: incompatibleURL)
        expect(unchangedIncompatibleBytes == incompatibleBytes, "The original library bytes stay at the original path even when future fields have incompatible shapes")

        try FileManager.default.createDirectory(at: emptyReload.recordingDirectoryURL, withIntermediateDirectories: true)
        let audioURL = emptyReload.audioURL(for: "test.m4a")!
        try Data([1, 2, 3]).write(to: audioURL)
        emptyReload.addDiary(type: .voice, content: "", duration: 3, audioFileName: "test.m4a")
        expect(AppModel(storageURL: url).diaries[0].audioFileName == "test.m4a", "Recorded audio references persist")
        emptyReload.deleteDiary(emptyReload.diaries[0].id)
        expect(!FileManager.default.fileExists(atPath: audioURL.path), "Deleting a recording cleans up its audio")
        expect(emptyReload.audioURL(for: "../outside.m4a") == nil, "Path traversal is rejected")
        expect(emptyReload.audioURL(for: "/tmp/outside.m4a") == nil, "Absolute paths are rejected")
        let externalURL = root.appendingPathComponent("outside.m4a")
        try Data([9]).write(to: externalURL)
        let symlinkURL = emptyReload.recordingDirectoryURL.appendingPathComponent("symlink.m4a")
        try FileManager.default.createSymbolicLink(at: symlinkURL, withDestinationURL: externalURL)
        expect(emptyReload.audioURL(for: "symlink.m4a") == nil, "Symlinks cannot escape the recordings directory")
        let childDirectory = emptyReload.recordingDirectoryURL.appendingPathComponent("folder.m4a")
        try FileManager.default.createDirectory(at: childDirectory, withIntermediateDirectories: true)
        expect(emptyReload.audioURL(for: "folder.m4a") == nil, "A recording filename cannot target a directory")
        let linkedModel = AppModel(storageURL: root.appendingPathComponent("linked/library.json"), seedSampleData: false)
        try FileManager.default.createSymbolicLink(at: linkedModel.recordingDirectoryURL, withDestinationURL: root)
        expect(linkedModel.audioURL(for: "outside.m4a") == nil, "The recordings directory cannot redirect cleanup outside the app")
        print("PASS: streaks, schedules, persistent CRUD, legacy decoding, corruption backup, future-schema safety, and recording cleanup")
    }
}
