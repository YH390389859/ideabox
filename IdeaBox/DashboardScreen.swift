import SwiftUI

struct DashboardScreen: View {
    var allowsAmbientMotion = true
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingStats = false
    @State private var showingHabit = false
    @State private var selectedItem: LibraryItem?
    @State private var referenceDate = Date()
    private var today: Date { referenceDate }
    private var habits: [Habit] { appModel.scheduledHabits(on: today) }
    private var completed: Int { appModel.completedHabits(on: today).count }
    private var calloutIndices: [Int] {
        guard !habits.isEmpty else { return [] }
        return [0, habits.count / 2, habits.count - 1].reduce(into: []) { result, index in
            if !result.contains(index) { result.append(index) }
        }
    }
    private var days: [Date] {
        (0..<7).compactMap { Calendar.ideabox.date(byAdding: .day, value: $0 - 6, to: today) }
    }
    private var threads: [WovenThread] {
        habits.map { habit in
            WovenThread(id: habit.id, color: Loom.threadColor(for: habit), completed: habit.isCompleted(on: today), history: days.map { habit.isCompleted(on: $0) })
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    header.id("dashboard-top")
                    if appModel.persistenceError != nil || appModel.recoveredBackupURL != nil { storageNotice }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今天，织一点。")
                            .font(.system(size: 31, weight: .medium)).tracking(-1.2).foregroundStyle(Loom.ink)
                        Text(habits.isEmpty ? "没有安排的日子，也可以很丰盛。" : completed == habits.count ? "今天的线，已经织好。" : "不必完美，每一根线都算数。")
                            .font(.system(size: 12)).foregroundStyle(Loom.secondary)
                    }
                    weaving
                    HStack {
                        LoomEyebrow(text: "TOUCH THE THREAD / 轻点线端打卡")
                        Spacer(minLength: 6)
                        Button { appModel.activate(tab: .habits) } label: {
                            Text("全部 \(habits.count) 根线 ↗").font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Loom.ink).frame(minHeight: 44)
                        }.buttonStyle(StudioPressStyle())
                    }
                    recent
                }
                .padding(.horizontal, 24).padding(.top, 4).padding(.bottom, 112)
            }
            .onChange(of: appModel.scrollTicket(for: .dashboard)) { _, _ in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { proxy.scrollTo("dashboard-top", anchor: .top) }
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            referenceDate = Date()
            while !Task.isCancelled {
                let now = Date()
                guard let nextDay = Calendar.ideabox.date(byAdding: .day, value: 1, to: Calendar.ideabox.startOfDay(for: now)) else { return }
                do { try await Task.sleep(for: .seconds(max(1, nextDay.timeIntervalSince(now)))) }
                catch { return }
                referenceDate = Date()
            }
        }
        .sheet(isPresented: $showingStats) {
            statsSheet.presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible).presentationCornerRadius(22)
                .presentationBackground(Loom.paper)
        }
        .sheet(isPresented: $showingHabit) { HabitEditorSheet().environmentObject(appModel) }
        .sheet(item: $selectedItem) { item in
            LibraryDetailSheet(item: item).environmentObject(appModel)
                .presentationDragIndicator(.visible).presentationCornerRadius(22)
                .presentationBackground(Loom.paper)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                LoomEyebrow(text: "01 / TODAY / ON THE LOOM")
                Spacer()
                Button { showingStats = true } label: { LoomSign().frame(width: 26, height: 26).frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(StudioPressStyle()).accessibilityLabel("查看我的积累")
            }
            HStack(alignment: .center, spacing: 21) {
                Text(today.formatted(.dateTime.day(.twoDigits)))
                    .font(.system(size: 74, weight: .light)).monospacedDigit().foregroundStyle(Loom.ink)
                    .fixedSize()
                VStack(alignment: .leading, spacing: 7) {
                    Text(today.formatted(.dateTime.month(.wide).locale(Locale(identifier: "zh_CN"))))
                        .font(.system(size: 18, weight: .medium)).foregroundStyle(Loom.ink)
                    Text(today.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "zh_CN"))))
                        .font(.system(size: 11)).foregroundStyle(Loom.secondary)
                }
                Spacer(minLength: 0)
                Button { showingStats = true } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(completed)").font(.system(size: 33, weight: .medium)).foregroundStyle(Loom.cobalt)
                                .contentTransition(.numericText())
                            Text("/ \(habits.count)").font(.system(size: 13)).foregroundStyle(Loom.secondary)
                        }
                        Text("今日已完成").font(.system(size: 9)).foregroundStyle(Loom.secondary)
                    }.padding(.leading, 18).overlay(alignment: .leading) { Rectangle().fill(Loom.hairline).frame(width: 0.8, height: 50) }
                }.buttonStyle(StudioPressStyle())
                    .accessibilityLabel("今天已完成 \(completed) 个，共 \(habits.count) 个习惯。查看积累")
            }
        }.animation(reduceMotion ? nil : Studio.spring, value: completed)
    }

    private var weaving: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            ZStack {
                WovenArtwork(threads: threads, active: allowsAmbientMotion && appModel.currentTab == .dashboard)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                if !habits.isEmpty {
                    calloutLines(width: w, height: h).allowsHitTesting(false)
                    ForEach(Array(calloutIndices.enumerated()), id: \.element) { position, habitIndex in
                        threadControl(habits[habitIndex])
                            .position(labelPosition(position, width: w, height: h))
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("先添一根线。")
                            .font(.system(size: 22, weight: .medium)).foregroundStyle(Loom.ink)
                        Button("创建第一个习惯") { showingHabit = true }
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(Loom.cobalt)
                            .frame(height: 44)
                    }.padding(22).background(Loom.paper.opacity(0.94))
                }
            }
        }.frame(height: 264)
        .sensoryFeedback(.success, trigger: completed)
    }

    private func threadControl(_ habit: Habit) -> some View {
        let done = habit.isCompleted(on: today)
        return Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.46, dampingFraction: 0.74)) {
                appModel.toggleHabit(habit.id, on: today)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12, weight: .regular)).foregroundStyle(Loom.threadColor(for: habit))
                Text(habit.name).font(.system(size: 10, weight: .medium)).lineLimit(1).minimumScaleFactor(0.8)
                    .foregroundStyle(Loom.ink)
            }
            .padding(.horizontal, 5).padding(.vertical, 6)
            .frame(width: 103, height: 44).contentShape(Rectangle())
        }.buttonStyle(StudioPressStyle())
            .accessibilityLabel("\(habit.name)，\(done ? "已完成，轻点撤销" : "未完成，轻点打卡")")
            .accessibilityIdentifier("home-thread-\(habit.id.uuidString)")
    }

    private func labelPosition(_ index: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        switch index {
        case 0: CGPoint(x: 51.5, y: 70)
        case 1: CGPoint(x: width - 51.5, y: 26)
        default: CGPoint(x: width - 51.5, y: height - 22)
        }
    }
    private func calloutLines(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(Array(calloutIndices.enumerated()), id: \.element) { position, habitIndex in
                let point = WovenArtwork.anchor(for: habitIndex, count: habits.count, at: [0.3, 0.15, 0.86][position], in: CGSize(width: width - 32, height: height - 20))
                let anchor = CGPoint(x: point.x + 16, y: point.y + 10)
                let label = labelPosition(position, width: width, height: height)
                let endpoint = CGPoint(x: label.x + (position == 0 ? 43 : -43), y: label.y)
                Path { path in
                    path.move(to: anchor)
                    path.addLine(to: CGPoint(x: endpoint.x, y: (anchor.y + endpoint.y) / 2))
                    path.addLine(to: endpoint)
                }.stroke(Loom.secondary.opacity(0.7), lineWidth: 0.65)
                Circle().fill(Loom.threadColor(for: habits[habitIndex])).frame(width: 4, height: 4).position(anchor)
            }
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 7) {
                    LoomEyebrow(text: "JUST CAUGHT")
                    Text("灵感，先留一线。").font(.system(size: 20, weight: .medium)).tracking(-0.7).foregroundStyle(Loom.ink)
                }
                Spacer()
                Button { appModel.activate(tab: .clips) } label: {
                    Image(systemName: "arrow.up.right").font(.system(size: 18, weight: .light)).frame(width: 44, height: 44)
                }.foregroundStyle(Loom.ink).buttonStyle(StudioPressStyle()).accessibilityLabel("打开全部收集")
            }
            if let item = appModel.libraryItems.first {
                Button { selectedItem = item } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("01 / \(materialLabel(item))").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1)
                            Spacer()
                            Text(item.dateAdded.formatted(.dateTime.hour().minute())).font(.system(size: 9, design: .monospaced))
                        }
                        Text(itemExcerpt(item)).font(.system(size: 15, weight: .medium)).lineSpacing(3).lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundStyle(isVoice(item) ? .white : Loom.ink)
                    .padding(.leading, 28).padding(.trailing, 20).padding(.vertical, 20)
                    .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                    .background(MaterialSampleSurface(kind: materialKind(item)))
                    .contentShape(Rectangle())
                }.buttonStyle(StudioPressStyle())
            } else {
                Button { appModel.openClipsComposer(.text) } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        LoomEyebrow(text: "YOUR FIRST PIECE")
                        Text("把此刻的一点念头，留在这里。")
                            .font(.system(size: 15, weight: .medium))
                        Text("写一条 ↗").font(.system(size: 12))
                    }.foregroundStyle(Loom.ink).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24).background(MaterialSampleSurface(kind: .text))
                }.buttonStyle(StudioPressStyle())
            }
        }
    }

    private func materialKind(_ item: LibraryItem) -> MaterialSampleKind {
        switch item { case .clip: .link; case .diary(let entry): entry.type == .voice ? .voice : .text }
    }
    private func materialLabel(_ item: LibraryItem) -> String {
        switch item { case .clip: "LINK"; case .diary(let entry): entry.type == .voice ? "VOICE" : "NOTE" }
    }
    private func isVoice(_ item: LibraryItem) -> Bool {
        if case .diary(let entry) = item { return entry.type == .voice }
        return false
    }
    private func itemExcerpt(_ item: LibraryItem) -> String {
        switch item {
        case .clip(let clip): clip.title
        case .diary(let diary): diary.content.isEmpty ? "一段此刻的声音。" : diary.content
        }
    }
    private var storageNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("存储状态", systemImage: "exclamationmark.circle").font(.system(size: 12, weight: .semibold))
            Text(appModel.persistenceError ?? "原记录读取时遇到问题，原文件已保留。你可以导出恢复文件。").font(.system(size: 11))
            HStack(spacing: 20) {
                if appModel.persistenceError != nil {
                    Button { appModel.save() } label: { Text("重试保存").frame(minHeight: 44) }
                }
                if let backup = appModel.recoveredBackupURL {
                    ShareLink(item: backup) { Text("导出恢复文件").frame(minHeight: 44) }
                }
            }.font(.system(size: 12, weight: .medium)).buttonStyle(.plain)
        }.foregroundStyle(Loom.clay).frame(maxWidth: .infinity, alignment: .leading).padding(14)
            .overlay(Rectangle().stroke(Loom.clay.opacity(0.4), lineWidth: 1))
    }

    private var statsSheet: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                LoomHeader(index: "YOUR WOVEN DAYS", title: "这些线，都是你。", subtitle: "每次留下的痕迹，都在这里。")
                Button { showingStats = false } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .foregroundStyle(Loom.ink).accessibilityLabel("关闭统计")
            }
            statRow("累计打卡", count: appModel.totalCheckIns, code: "KNOTS")
            statRow("珍藏灵感", count: appModel.collectionCount, code: "PIECES")
            statRow("当前最长连续", count: appModel.bestStreak, code: "IN A ROW")
            Label("内容保存在这台设备上", systemImage: "lock")
                .font(.system(size: 11)).foregroundStyle(Loom.secondary)
            Spacer(minLength: 0)
        }.padding(24)
    }
    private func statRow(_ label: String, count: Int, code: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(count)").font(.system(size: 42, weight: .light)).foregroundStyle(Loom.cobalt).frame(minWidth: 66, alignment: .leading)
            Text(label).font(.system(size: 15)).foregroundStyle(Loom.ink)
            Spacer()
            LoomEyebrow(text: code)
        }.padding(.bottom, 12).overlay(alignment: .bottom) { Rectangle().fill(Loom.hairline).frame(height: 0.8) }
    }
}
