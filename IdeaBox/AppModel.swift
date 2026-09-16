import Foundation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Codable {
    case dashboard
    case habits
    case clips

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "总览"
        case .habits: "打卡"
        case .clips: "收集"
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .habits: "checkmark.circle"
        case .clips: "bookmark"
        }
    }

    var assetName: String {
        switch self {
        case .dashboard: "TabOverview"
        case .habits: "TabCheckIn"
        case .clips: "TabClips"
        }
    }
}

enum ComposerKind: String, Identifiable, Codable {
    case voice
    case text
    case link

    var id: String { rawValue }
}

enum HabitFrequency: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekday
    case weekly
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: "每天"
        case .weekday: "工作日"
        case .weekly: "每周"
        case .custom: "自定义"
        }
    }
}

enum HabitPalette: String, CaseIterable, Codable {
    case blue
    case cyan
    case rose
    case amber
    case indigo
    case purple
    case pink
    case green
    case teal
    case yellow

    var lightColor: Color {
        switch self {
        case .blue: Color(hex: 0xDBEAFE)
        case .cyan: Color(hex: 0xCFFAFE)
        case .rose: Color(hex: 0xFFE4E6)
        case .amber: Color(hex: 0xFEF3C7)
        case .indigo: Color(hex: 0xE0E7FF)
        case .purple: Color(hex: 0xF3E8FF)
        case .pink: Color(hex: 0xFCE7F3)
        case .green: Color(hex: 0xDCFCE7)
        case .teal: Color(hex: 0xCCFBF1)
        case .yellow: Color(hex: 0xFEF9C3)
        }
    }

    var darkColor: Color {
        switch self {
        case .blue: Color(hex: 0x2563EB)
        case .cyan: Color(hex: 0x0891B2)
        case .rose: Color(hex: 0xE11D48)
        case .amber: Color(hex: 0xD97706)
        case .indigo: Color(hex: 0x4F46E5)
        case .purple: Color(hex: 0x9333EA)
        case .pink: Color(hex: 0xDB2777)
        case .green: Color(hex: 0x16A34A)
        case .teal: Color(hex: 0x0F766E)
        case .yellow: Color(hex: 0xCA8A04)
        }
    }
}

enum HabitIcon: String, CaseIterable, Identifiable, Codable {
    case bookOpen = "BookOpen"
    case droplets = "Droplets"
    case dumbbell = "Dumbbell"
    case coffee = "Coffee"
    case moon = "Moon"
    case pencil = "Pencil"
    case music = "Music"
    case apple = "Apple"
    case brain = "Brain"
    case sun = "Sun"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bookOpen: "阅读"
        case .droplets: "喝水"
        case .dumbbell: "锻炼"
        case .coffee: "冥想"
        case .moon: "睡眠"
        case .pencil: "写作"
        case .music: "音乐"
        case .apple: "饮食"
        case .brain: "学习"
        case .sun: "户外"
        }
    }

    var symbolName: String {
        switch self {
        case .bookOpen: "book.closed"
        case .droplets: "drop"
        case .dumbbell: "dumbbell"
        case .coffee: "cup.and.saucer"
        case .moon: "moon"
        case .pencil: "pencil.line"
        case .music: "music.note"
        case .apple: "applelogo"
        case .brain: "brain.head.profile"
        case .sun: "sun.max"
        }
    }

    var assetName: String {
        switch self {
        case .bookOpen: "HabitBook"
        case .droplets: "HabitWater"
        case .dumbbell: "HabitWorkout"
        case .coffee: "HabitMeditation"
        case .moon: "HabitMoon"
        case .pencil: "HabitPencil"
        case .music: "HabitMusic"
        case .apple: "HabitApple"
        case .brain: "HabitBrain"
        case .sun: "HabitSun"
        }
    }

    var emoji: String {
        switch self {
        case .bookOpen: "📖"
        case .droplets: "💧"
        case .dumbbell: "💪"
        case .coffee: "☕"
        case .moon: "🌙"
        case .pencil: "✏️"
        case .music: "🎵"
        case .apple: "🍎"
        case .brain: "🧠"
        case .sun: "☀️"
        }
    }

    var palette: HabitPalette {
        switch self {
        case .bookOpen: .blue
        case .droplets: .cyan
        case .dumbbell: .rose
        case .coffee: .amber
        case .moon: .indigo
        case .pencil: .purple
        case .music: .pink
        case .apple: .green
        case .brain: .teal
        case .sun: .yellow
        }
    }
}

enum DiaryType: String, Codable {
    case voice
    case text
}

enum DiaryMood: String, CaseIterable, Codable {
    case happy
    case excited
    case satisfied
    case inspired
    case relaxed

    var emoji: String {
        switch self {
        case .happy: "😊"
        case .excited: "🤩"
        case .satisfied: "😌"
        case .inspired: "💡"
        case .relaxed: "😮‍💨"
        }
    }
}

enum ClipFilter: String, CaseIterable, Identifiable, Codable {
    case all
    case voice
    case text
    case link

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "全部"
        case .voice: "语音"
        case .text: "文字"
        case .link: "链接"
        }
    }

    var symbolName: String? {
        switch self {
        case .all: nil
        case .voice: "mic.fill"
        case .text: "text.alignleft"
        case .link: "link"
        }
    }
}

struct Habit: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var icon: HabitIcon
    var completedDates: Set<String>
    var frequency: HabitFrequency

    /// Gregorian weekdays: 1 = Sunday, 2 = Monday, …, 7 = Saturday.
    /// Weekly habits default to Sunday; custom habits default to Monday/Wednesday/Friday.
    var scheduledWeekdays: Set<Int>? = nil

    var palette: HabitPalette { icon.palette }
    var streak: Int { streak(endingOn: Date()) }
    var totalCompletions: Int { completedDates.count }

    var activeWeekdays: Set<Int> {
        switch frequency {
        case .daily: Set(1...7)
        case .weekday: Set(2...6)
        case .weekly: [scheduledWeekdays?.filter { (1...7).contains($0) }.sorted().first ?? 1]
        case .custom:
            if let validDays = scheduledWeekdays?.filter({ (1...7).contains($0) }), !validDays.isEmpty {
                Set(validDays)
            } else {
                [2, 4, 6]
            }
        }
    }

    var scheduleDescription: String {
        switch frequency {
        case .daily: "每天"
        case .weekday: "周一至周五"
        case .weekly, .custom:
            activeWeekdays.sorted { ($0 + 5) % 7 < ($1 + 5) % 7 }
                .map { ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"][$0] }
                .joined(separator: "、")
        }
    }

    func isScheduled(on date: Date, calendar: Calendar = .ideabox) -> Bool {
        activeWeekdays.contains(calendar.component(.weekday, from: date))
    }

    func isCompleted(on date: Date) -> Bool {
        completedDates.contains(date.dayKey)
    }

    /// Consecutive scheduled check-ins. An unfinished current day does not break the streak.
    /// Rest days are skipped, and future check-ins never contribute.
    func streak(endingOn date: Date, calendar: Calendar = .ideabox) -> Int {
        guard let earliest = completedDates.compactMap({ AppFormatters.dayKey.date(from: $0) }).min() else {
            return 0
        }
        let today = calendar.startOfDay(for: date)
        var cursor = today
        if isScheduled(on: cursor, calendar: calendar), !isCompleted(on: cursor) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }
        var count = 0
        while cursor >= calendar.startOfDay(for: earliest) {
            if isScheduled(on: cursor, calendar: calendar) {
                guard isCompleted(on: cursor) else { break }
                count += 1
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}

struct ClipItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var url: String
    var excerpt: String
    var tags: [String]
    var dateAdded: Date
}

struct DiaryEntry: Identifiable, Equatable, Codable {
    let id: UUID
    var type: DiaryType
    var content: String
    var richTextData: Data?
    var duration: Int?
    var mood: DiaryMood?
    var tags: [String]
    var dateAdded: Date
    var audioFileName: String? = nil
}

enum LibraryItem: Identifiable, Equatable, Codable {
    case clip(ClipItem)
    case diary(DiaryEntry)

    var id: UUID {
        switch self {
        case .clip(let clip): clip.id
        case .diary(let diary): diary.id
        }
    }

    var dateAdded: Date {
        switch self {
        case .clip(let clip): clip.dateAdded
        case .diary(let diary): diary.dateAdded
        }
    }

    var tags: [String] {
        switch self {
        case .clip(let clip): clip.tags
        case .diary(let diary): diary.tags
        }
    }
}

final class AppModel: ObservableObject {
    @Published var currentTab: AppTab = .dashboard
    @Published var habits: [Habit] { didSet { trackHabitChanges(from: oldValue); persistIfReady() } }
    @Published var clips: [ClipItem] { didSet { trackRecordChanges(oldValue, clips, prefix: "clip"); persistIfReady() } }
    @Published var diaries: [DiaryEntry] { didSet { trackRecordChanges(oldValue, diaries, prefix: "diary"); persistIfReady() } }
    @Published private(set) var agentReceipts: [AgentToolReceipt] = []
    @Published private(set) var persistenceError: String?
    @Published private(set) var recoveredBackupURL: URL?

    let storageURL: URL
    let recordingDirectoryURL: URL
    private var canPersist = false
    private var isAgentTransaction = false
    private var isRestoringAgentSnapshot = false
    var agentOperations: [AgentOperationRecord] = []
    var agentRecordRevisions: [String: String] = [:]

    static var defaultStorageURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("IdeaBox", isDirectory: true)
            .appendingPathComponent("library.json")
    }

    static var recordingsDirectory: URL {
        defaultStorageURL.deletingLastPathComponent().appendingPathComponent("Recordings", isDirectory: true)
    }
    @Published private var scrollStates: [AppTab: Bool]
    @Published private var scrollTickets: [AppTab: Int]
    @Published var pendingComposer: ComposerKind?

    init(storageURL: URL? = nil, seedSampleData: Bool = true) {
        let resolvedURL = storageURL ?? Self.defaultStorageURL
        self.storageURL = resolvedURL
        recordingDirectoryURL = resolvedURL.deletingLastPathComponent()
            .appendingPathComponent("Recordings", isDirectory: true)
        let today = Date()
        let todayKey = today.dayKey
        let yesterdayKey = Calendar.ideabox.date(byAdding: .day, value: -1, to: today)?.dayKey ?? todayKey
        let twoDaysAgoKey = Calendar.ideabox.date(byAdding: .day, value: -2, to: today)?.dayKey ?? todayKey
        let threeDaysAgoKey = Calendar.ideabox.date(byAdding: .day, value: -3, to: today)?.dayKey ?? todayKey

        habits = [
            Habit(id: UUID(), name: "阅读 30 分钟", icon: .bookOpen, completedDates: [yesterdayKey], frequency: .daily),
            Habit(id: UUID(), name: "喝水 8 杯", icon: .droplets, completedDates: [], frequency: .daily),
            Habit(id: UUID(), name: "锻炼", icon: .dumbbell, completedDates: [todayKey], frequency: .daily),
            Habit(id: UUID(), name: "早起冥想", icon: .coffee, completedDates: [todayKey, yesterdayKey], frequency: .daily),
            Habit(id: UUID(), name: "写日记", icon: .pencil, completedDates: [], frequency: .daily),
            Habit(id: UUID(), name: "早睡（11点前）", icon: .moon, completedDates: [twoDaysAgoKey], frequency: .weekday),
            Habit(id: UUID(), name: "吃一份水果", icon: .apple, completedDates: [todayKey], frequency: .daily),
            Habit(id: UUID(), name: "练习英语听力", icon: .music, completedDates: [], frequency: .weekday),
            Habit(id: UUID(), name: "学习新知识 20 分钟", icon: .brain, completedDates: [yesterdayKey, threeDaysAgoKey], frequency: .daily),
            Habit(id: UUID(), name: "晒太阳 15 分钟", icon: .sun, completedDates: [], frequency: .daily)
        ]

        clips = [
            ClipItem(id: UUID(), title: "React 19 新特性解析", url: "https://react.dev/blog/2024/04/25/react-19", excerpt: "了解 React 19 中引入的 Hooks、Actions 等新特性，以及如何迁移旧代码。", tags: ["技术", "前端", "React"], dateAdded: today.addingTimeInterval(-86_400)),
            ClipItem(id: UUID(), title: "好用的设计灵感网站收集", url: "https://dribbble.com", excerpt: "包含优秀的 UI/UX 设计案例，可以在设计应用时提供配色和排版参考。", tags: ["设计", "灵感"], dateAdded: today.addingTimeInterval(-3_600)),
            ClipItem(id: UUID(), title: "Tailwind CSS v4 完全指南", url: "https://tailwindcss.com/blog/tailwindcss-v4", excerpt: "深入了解 Tailwind CSS v4 的全新架构、零配置体验和性能提升。", tags: ["技术", "前端"], dateAdded: today.addingTimeInterval(-172_800)),
            ClipItem(id: UUID(), title: "极简主义生活方式", url: "https://example.com/minimalism", excerpt: "如何通过减少物质负担来提升生活质量，从衣橱整理到数字断舍离。", tags: ["生活", "灵感"], dateAdded: today.addingTimeInterval(-259_200)),
            ClipItem(id: UUID(), title: "TypeScript 5.5 新功能一览", url: "https://devblogs.microsoft.com/typescript", excerpt: "类型推断增强、独立声明文件等新功能让开发体验更加流畅。", tags: ["技术", "前端"], dateAdded: today.addingTimeInterval(-345_600)),
            ClipItem(id: UUID(), title: "每天 5 分钟冥想入门", url: "https://example.com/meditation", excerpt: "科学证明冥想可以降低焦虑、提升专注力，从短时间练习开始建立习惯。", tags: ["生活", "健康"], dateAdded: today.addingTimeInterval(-432_000)),
            ClipItem(id: UUID(), title: "Figma 自动布局高级技巧", url: "https://figma.com/blog/auto-layout", excerpt: "掌握 Auto Layout 的嵌套、间距控制和响应式设计，让设计稿更规范。", tags: ["设计", "工具"], dateAdded: today.addingTimeInterval(-518_400)),
            ClipItem(id: UUID(), title: "2026 年值得关注的开源项目", url: "https://example.com/opensource-2026", excerpt: "从 AI 框架到开发工具，盘点今年最具潜力的开源项目。", tags: ["技术", "灵感"], dateAdded: today.addingTimeInterval(-604_800))
        ]

        diaries = [
            DiaryEntry(id: UUID(), type: .text, content: "今天尝试了一种新的时间管理方法，25 分钟专注加 5 分钟休息，效率提升很明显。下午把积压的设计稿全部完成了，成就感满满。", richTextData: nil, duration: nil, mood: .satisfied, tags: ["工作", "效率"], dateAdded: today.addingTimeInterval(-3_600)),
            DiaryEntry(id: UUID(), type: .voice, content: "晚上去公园散步，遇到了一只特别可爱的金毛犬，主人说它叫饺子，太有意思了。春天的风吹着特别舒服。", richTextData: nil, duration: 45, mood: .happy, tags: ["生活", "心情"], dateAdded: today.addingTimeInterval(-86_400)),
            DiaryEntry(id: UUID(), type: .text, content: "读完了《原子习惯》最后两章，核心观点是微小改变带来巨大成果。准备把书里的习惯叠加方法用起来。", richTextData: nil, duration: nil, mood: .inspired, tags: ["阅读", "学习"], dateAdded: today.addingTimeInterval(-172_800)),
            DiaryEntry(id: UUID(), type: .voice, content: "今天和老朋友视频聊了一个多小时，聊了很多以前的事情，笑到肚子疼。好久没有这么开心了。", richTextData: nil, duration: 68, mood: .excited, tags: ["社交"], dateAdded: today.addingTimeInterval(-345_600))
        ]

        scrollStates = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, false) })
        scrollTickets = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, 0) })
        if !seedSampleData {
            habits = []
            clips = []
            diaries = []
        }
        restoreFromDisk()
        #if DEBUG
        if let value = ProcessInfo.processInfo.environment["IDEABOX_PREVIEW_TAB"], let tab = AppTab(rawValue: value) {
            currentTab = tab
        }
        #endif
    }

    var libraryItems: [LibraryItem] {
        (clips.map(LibraryItem.clip) + diaries.map(LibraryItem.diary))
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    var allTags: [String] {
        Array(Set(libraryItems.flatMap(\.tags))).sorted()
    }

    var totalCheckIns: Int { habits.reduce(0) { $0 + $1.totalCompletions } }
    var bestStreak: Int { habits.map(\.streak).max() ?? 0 }
    var collectionCount: Int { clips.count + diaries.count }

    func scheduledHabits(on date: Date) -> [Habit] {
        habits.filter { $0.isScheduled(on: date) }
    }

    func completedHabits(on date: Date) -> [Habit] {
        scheduledHabits(on: date).filter { $0.isCompleted(on: date) }
    }

    func completionRate(on date: Date) -> Double {
        let scheduled = scheduledHabits(on: date)
        guard !scheduled.isEmpty else { return 0 }
        return Double(scheduled.filter { $0.isCompleted(on: date) }.count) / Double(scheduled.count)
    }

    func collectionCount(on date: Date) -> Int {
        libraryItems.filter { Calendar.ideabox.isDate($0.dateAdded, inSameDayAs: date) }.count
    }

    func isScrolled(_ tab: AppTab) -> Bool {
        scrollStates[tab] ?? false
    }

    func scrollTicket(for tab: AppTab) -> Int {
        scrollTickets[tab] ?? 0
    }

    func setScrollState(_ isScrolled: Bool, for tab: AppTab) {
        guard scrollStates[tab] != isScrolled else { return }
        scrollStates[tab] = isScrolled
    }

    func activate(tab: AppTab) {
        currentTab = tab
    }

    func requestScrollToTop(for tab: AppTab) {
        scrollTickets[tab, default: 0] += 1
    }

    func openClipsComposer(_ kind: ComposerKind) {
        currentTab = .clips
        pendingComposer = kind
    }

    func consumePendingComposer() -> ComposerKind? {
        defer { pendingComposer = nil }
        return pendingComposer
    }

    func toggleHabit(_ habitID: UUID, on date: Date) {
        guard Calendar.ideabox.startOfDay(for: date) <= Calendar.ideabox.startOfDay(for: Date()),
              let index = habits.firstIndex(where: { $0.id == habitID }) else { return }
        let key = date.dayKey
        if habits[index].completedDates.contains(key) {
            habits[index].completedDates.remove(key)
        } else if habits[index].isScheduled(on: date) {
            habits[index].completedDates.insert(key)
        }
    }

    func addHabit(name: String, icon: HabitIcon, frequency: HabitFrequency, scheduledWeekdays: Set<Int>? = nil) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        habits.insert(
            Habit(id: UUID(), name: name, icon: icon, completedDates: [], frequency: frequency, scheduledWeekdays: scheduledWeekdays),
            at: 0
        )
    }

    func updateHabit(_ habitID: UUID, name: String, icon: HabitIcon, frequency: HabitFrequency, scheduledWeekdays: Set<Int>? = nil) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let index = habits.firstIndex(where: { $0.id == habitID }) else { return }
        var habit = habits[index]
        habit.name = name
        habit.icon = icon
        habit.frequency = frequency
        habit.scheduledWeekdays = scheduledWeekdays
        habits[index] = habit
    }

    func deleteHabit(_ habitID: UUID) {
        habits.removeAll { $0.id == habitID }
    }

    func addClip(title: String, url: String, excerpt: String, tags: [String] = ["未分类"]) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        clips.insert(
            ClipItem(id: UUID(), title: title, url: url.trimmingCharacters(in: .whitespacesAndNewlines),
                     excerpt: excerpt, tags: normalizedTags(tags), dateAdded: Date()),
            at: 0
        )
    }

    func updateClip(_ clipID: UUID, title: String, url: String, excerpt: String, tags: [String]? = nil) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let index = clips.firstIndex(where: { $0.id == clipID }) else { return }
        var clip = clips[index]
        clip.title = title
        clip.url = url.trimmingCharacters(in: .whitespacesAndNewlines)
        clip.excerpt = excerpt
        if let tags { clip.tags = normalizedTags(tags) }
        clips[index] = clip
    }

    func deleteClip(_ clipID: UUID) {
        clips.removeAll { $0.id == clipID }
    }

    func addDiary(type: DiaryType, content: String, richTextData: Data? = nil, duration: Int? = nil,
                  audioFileName: String? = nil, tags: [String] = ["日记"], mood: DiaryMood? = .happy) {
        let safeAudioName = type == .voice && audioURL(for: audioFileName) != nil ? audioFileName : nil
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || safeAudioName != nil else { return }
        diaries.insert(
            DiaryEntry(id: UUID(), type: type, content: content, richTextData: richTextData,
                       duration: duration.map { max(0, $0) }, mood: mood, tags: normalizedTags(tags),
                       dateAdded: Date(), audioFileName: safeAudioName),
            at: 0
        )
    }

    func updateDiary(_ diaryID: UUID, content: String, richTextData: Data? = nil,
                     tags: [String]? = nil, mood: DiaryMood? = nil) {
        guard let index = diaries.firstIndex(where: { $0.id == diaryID }),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || diaries[index].audioFileName != nil else { return }
        var entry = diaries[index]
        entry.content = content
        entry.richTextData = richTextData
        if let tags { entry.tags = normalizedTags(tags) }
        if let mood { entry.mood = mood }
        diaries[index] = entry
    }

    func deleteDiary(_ diaryID: UUID) {
        let removedEntry = diaries.first { $0.id == diaryID }
        diaries.removeAll { $0.id == diaryID }
        // Preserve the original audio if saving failed, so the on-disk entry remains playable.
        guard canPersist, persistenceError == nil, let fileName = removedEntry?.audioFileName,
              !diaries.contains(where: { $0.audioFileName == fileName }),
              let url = audioURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Only files directly inside this app's recording directory can be read or removed.
    func audioURL(for fileName: String?) -> URL? {
        guard let fileName, !fileName.isEmpty, fileName != ".", fileName != "..",
              !fileName.contains("/"), !fileName.contains("\\"),
              (fileName as NSString).lastPathComponent == fileName else { return nil }
        if (try? recordingDirectoryURL.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true {
            return nil
        }
        let directory = recordingDirectoryURL.standardizedFileURL.resolvingSymlinksInPath()
        let candidate = directory.appendingPathComponent(fileName).standardizedFileURL
        guard candidate.resolvingSymlinksInPath().deletingLastPathComponent() == directory else { return nil }
        if let attributes = try? candidate.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
           attributes.isDirectory == true || attributes.isSymbolicLink == true {
            return nil
        }
        return candidate
    }

    @discardableResult
    func save() -> Bool {
        guard canPersist else { return false }
        do {
            try FileManager.default.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(StoredLibrary(habits: habits, clips: clips, diaries: diaries,
                                                       agentOperations: agentOperations, agentRecordRevisions: agentRecordRevisions))
            try data.write(to: storageURL, options: .atomic)
            persistenceError = nil
            return true
        } catch {
            persistenceError = "暂时无法保存记录：\(error.localizedDescription)"
            return false
        }
    }

    private func persistIfReady() {
        if canPersist && !isAgentTransaction { save() }
    }

    /// A tool's record, idempotency entry and undo state are committed as one file replacement.
    /// A failed replacement restores every in-memory field before returning a failure receipt.
    func commitAgentOperation(operationID: String, _ mutate: () -> AgentToolReceipt) -> AgentToolReceipt {
        guard canPersist, !isAgentTransaction else {
            return .failure(id: operationID, "本地记录暂时无法保存，这次操作没有执行。")
        }
        let previousHabits = habits
        let previousClips = clips
        let previousDiaries = diaries
        let previousOperations = agentOperations
        let previousRevisions = agentRecordRevisions
        isAgentTransaction = true
        let receipt = mutate()
        refreshAgentReceipts()
        if receipt.success && save() {
            isAgentTransaction = false
            return agentReceipt(for: receipt.id) ?? receipt
        }
        isRestoringAgentSnapshot = true
        habits = previousHabits
        clips = previousClips
        diaries = previousDiaries
        agentOperations = previousOperations
        agentRecordRevisions = previousRevisions
        refreshAgentReceipts()
        isRestoringAgentSnapshot = false
        isAgentTransaction = false
        return receipt.success ? .failure(id: operationID, "本地保存失败，这次操作没有生效。请稍后重试。") : receipt
    }

    func refreshAgentReceipts() {
        agentReceipts = agentOperations.map { operation in
            var receipt = operation.receipt
            receipt.canUndo = canUndoAgentOperation(operation)
            return receipt
        }
    }

    private func trackRecordChanges<T: Identifiable & Equatable>(_ before: [T], _ after: [T], prefix: String) where T.ID == UUID {
        guard canPersist, !isRestoringAgentSnapshot else { return }
        let old = Dictionary(before.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let new = Dictionary(after.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for id in Set(old.keys).union(new.keys) where old[id] != new[id] {
            agentRecordRevisions["\(prefix)/\(id.uuidString)"] = UUID().uuidString
        }
        refreshAgentReceipts()
    }

    private func trackHabitChanges(from before: [Habit]) {
        guard canPersist, !isRestoringAgentSnapshot else { return }
        let old = Dictionary(before.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let new = Dictionary(habits.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for id in Set(old.keys).union(new.keys) {
            let previous = old[id]
            let current = new[id]
            if previous?.name != current?.name || previous?.icon != current?.icon ||
                previous?.frequency != current?.frequency || previous?.scheduledWeekdays != current?.scheduledWeekdays {
                agentRecordRevisions["habit/\(id.uuidString)"] = UUID().uuidString
            }
            for key in (previous?.completedDates ?? []).symmetricDifference(current?.completedDates ?? []) {
                agentRecordRevisions["habit/\(id.uuidString)/\(key)"] = UUID().uuidString
            }
        }
        refreshAgentReceipts()
    }

    private func normalizedTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private func restoreFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            canPersist = true
            save()
            return
        }
        let data: Data
        do {
            data = try Data(contentsOf: storageURL)
        } catch {
            habits = []
            clips = []
            diaries = []
            persistenceError = "暂时无法读取本地记录，原文件已保留：\(error.localizedDescription)"
            return
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            // Read only the stable header first: a newer schema may change every other field.
            let header = try decoder.decode(StoredLibraryHeader.self, from: data)
            guard (1...2).contains(header.schemaVersion) else {
                habits = []
                clips = []
                diaries = []
                persistenceError = "本地记录来自更新版本，请更新应用。原文件已保留。"
                return
            }
            let stored = try decoder.decode(StoredLibrary.self, from: data)
            habits = stored.habits
            clips = stored.clips
            diaries = stored.diaries
            agentOperations = stored.agentOperations
            agentRecordRevisions = stored.agentRecordRevisions
            canPersist = true
            refreshAgentReceipts()
        } catch {
            // Never replace an unreadable library until its original bytes have been backed up.
            let backup = storageURL.deletingPathExtension()
                .appendingPathExtension("corrupt-\(UUID().uuidString).json")
            habits = []
            clips = []
            diaries = []
            do {
                try FileManager.default.moveItem(at: storageURL, to: backup)
                recoveredBackupURL = backup
                canPersist = true
                save()
            } catch {
                persistenceError = "本地记录无法读取，原文件已保留：\(error.localizedDescription)"
            }
        }
    }

    private struct StoredLibraryHeader: Decodable {
        let schemaVersion: Int
    }

    private struct StoredLibrary: Codable {
        var schemaVersion = 2
        var habits: [Habit]
        var clips: [ClipItem]
        var diaries: [DiaryEntry]
        var agentOperations: [AgentOperationRecord]
        var agentRecordRevisions: [String: String]

        init(habits: [Habit], clips: [ClipItem], diaries: [DiaryEntry],
             agentOperations: [AgentOperationRecord], agentRecordRevisions: [String: String]) {
            self.habits = habits
            self.clips = clips
            self.diaries = diaries
            self.agentOperations = agentOperations
            self.agentRecordRevisions = agentRecordRevisions
        }

        enum CodingKeys: String, CodingKey { case schemaVersion, habits, clips, diaries, agentOperations, agentRecordRevisions }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
            habits = try values.decode([Habit].self, forKey: .habits)
            clips = try values.decode([ClipItem].self, forKey: .clips)
            diaries = try values.decode([DiaryEntry].self, forKey: .diaries)
            agentOperations = try values.decodeIfPresent([AgentOperationRecord].self, forKey: .agentOperations) ?? []
            agentRecordRevisions = try values.decodeIfPresent([String: String].self, forKey: .agentRecordRevisions) ?? [:]
        }
    }

}

extension Calendar {
    static let ideabox: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2
        return calendar
    }()
}

enum AppFormatters {
    static let locale = Locale(identifier: "zh_CN")

    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .ideabox
        formatter.locale = locale
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let monthTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .ideabox
        formatter.locale = locale
        formatter.dateFormat = "M月"
        return formatter
    }()

    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .ideabox
        formatter.locale = locale
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let monthDayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .ideabox
        formatter.locale = locale
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static let fullDayTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .ideabox
        formatter.locale = locale
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()

    static let weekSymbol: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .ideabox
        formatter.locale = locale
        formatter.dateFormat = "E"
        return formatter
    }()

    static let dayNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .ideabox
        formatter.locale = locale
        formatter.dateFormat = "d"
        return formatter
    }()
}

extension Date {
    var dayKey: String {
        AppFormatters.dayKey.string(from: self)
    }

    var monthTitle: String {
        AppFormatters.monthTitle.string(from: self)
    }

    var monthDayTitle: String {
        AppFormatters.monthDay.string(from: self)
    }

    var monthDayTimeTitle: String {
        AppFormatters.monthDayTime.string(from: self)
    }

    var fullDayTitle: String {
        AppFormatters.fullDayTitle.string(from: self)
    }

    var weekSymbol: String {
        AppFormatters.weekSymbol.string(from: self)
    }

    var dayNumberTitle: String {
        AppFormatters.dayNumber.string(from: self)
    }
}
