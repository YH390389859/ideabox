import SwiftUI

struct HabitsScreen: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .body) private var scaledRowHeight = 76.0
    @ScaledMetric(relativeTo: .body) private var scaledLabelWidth = 96.0
    @ScaledMetric(relativeTo: .body) private var labelFontSize = 13.0
    @ScaledMetric(relativeTo: .caption) private var captionFontSize = 10.0
    @State private var weekCursor = HabitWeekCursor()
    @State private var isShowingAddHabit = false
    @State private var editingHabit: Habit?
    @State private var deletingHabit: Habit?
    @State private var checkInFeedback = 0

    private let dayWidth: CGFloat = 44
    private let columnHeaderHeight: CGFloat = 72
    private var rowHeight: CGFloat { max(76, scaledRowHeight) }
    private var labelWidth: CGFloat { min(128, max(96, scaledLabelWidth)) }
    private var today: Date { weekCursor.today }
    private var selectedDate: Date { weekCursor.selectedDate }
    private var currentWeek: [Date] { weekCursor.days }
    private var rangeTitle: String {
        guard let first = currentWeek.first, let last = currentWeek.last else { return "" }
        return "\(shortDate(first)) — \(shortDate(last))"
    }
    private var selectionSummary: String {
        let scheduled = appModel.scheduledHabits(on: selectedDate).count
        guard scheduled > 0 else { return "\(selectedDate.monthDayTitle) · 这一天没有安排" }
        return "\(selectedDate.monthDayTitle) · \(appModel.completedHabits(on: selectedDate).count) / \(scheduled) 已完成"
    }

    var body: some View {
        ScrollViewReader { verticalProxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    LoomHeader(index: "02 / HABITS / EVERY THREAD COUNTS", title: "把日子，织起来。", subtitle: "一根线，一个习惯。")
                        .id("habits-top")
                        .padding(.bottom, 19)
                    weekNavigation
                    Rectangle().fill(Loom.hairline).frame(height: 0.7)
                    if appModel.habits.isEmpty {
                        emptyState
                    } else {
                        matrix
                        matrixFootnote
                    }
                    addHabitButton
                        .padding(.top, 15)
                    if !appModel.habits.isEmpty {
                        Text("\(appModel.habits.count) 根线 · 每一根都有自己的节奏")
                            .font(.system(size: 10))
                            .foregroundStyle(Loom.secondary)
                            .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 108)
                .frame(maxWidth: 650)
                .frame(maxWidth: .infinity)
            }
            .background(Loom.paper)
            .onChange(of: appModel.scrollTicket(for: .habits)) { _, _ in
                withAnimation(reduceMotion ? nil : Studio.spring) {
                    verticalProxy.scrollTo("habits-top", anchor: .top)
                }
            }
        }
        .sheet(isPresented: $isShowingAddHabit) { HabitEditorSheet() }
        .sheet(item: $editingHabit) { HabitEditorSheet(habit: $0) }
        .confirmationDialog("删除这个习惯？", isPresented: Binding(
            get: { deletingHabit != nil }, set: { if !$0 { deletingHabit = nil } }
        ), titleVisibility: .visible) {
            if let habit = deletingHabit {
                Button("删除「\(habit.name)」", role: .destructive) {
                    withAnimation(reduceMotion ? nil : Studio.spring) { appModel.deleteHabit(habit.id) }
                    deletingHabit = nil
                }
            }
            Button("取消", role: .cancel) { deletingHabit = nil }
        } message: {
            Text("这个习惯和它的打卡记录将一起删除。")
        }
        .sensoryFeedback(.success, trigger: checkInFeedback)
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in synchronizeCalendarDay() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { synchronizeCalendarDay() }
        }
        .onChange(of: appModel.currentTab) { _, tab in
            if tab == .habits { synchronizeCalendarDay() }
        }
    }

    private var weekNavigation: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rangeTitle)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Loom.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text("\(String(Calendar.ideabox.component(.year, from: currentWeek.first ?? today))) / 时间织机 · 左右滑动")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Loom.secondary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
            if !weekCursor.isCurrentWeek || selectedDate != today {
                Button("今天") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24)) {
                        weekCursor.returnToToday()
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Loom.cobalt)
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(StudioPressStyle())
                .accessibilityLabel("返回今天")
            }
            weekArrow("chevron.left", label: "上一周", disabled: false) { changeWeek(by: -1) }
            weekArrow("chevron.right", label: "下一周", disabled: !weekCursor.canAdvanceWeek) { changeWeek(by: 1) }
        }
        .padding(.bottom, 10)
    }

    private func weekArrow(_ symbol: String, label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Loom.ink.opacity(disabled ? 0.25 : 1))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    private var matrix: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 13) {
                    Text("THREAD")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Loom.secondary)
                    Text("习惯")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Loom.ink)
                }
                .frame(width: labelWidth, height: columnHeaderHeight, alignment: .leading)
                ForEach(appModel.habits) { habit in
                    habitLabel(habit)
                }
            }
            .frame(width: labelWidth)

            ScrollViewReader { horizontalProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(currentWeek, id: \.dayKey) { day in
                                dateHeader(day).id(day.dayKey)
                            }
                        }
                        ForEach(appModel.habits) { habit in
                            HStack(spacing: 0) {
                                ForEach(currentWeek, id: \.dayKey) { day in
                                    intersection(habit: habit, day: day)
                                }
                            }
                            .background { weftLines(color: Loom.threadColor(for: habit)) }
                        }
                    }
                    .frame(width: dayWidth * CGFloat(currentWeek.count))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: columnHeaderHeight + rowHeight * CGFloat(appModel.habits.count))
                .task(id: weekCursor.weekStart) {
                    horizontalProxy.scrollTo(selectedDate.dayKey, anchor: .trailing)
                }
                .onChange(of: selectedDate) { _, date in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) {
                        horizontalProxy.scrollTo(date.dayKey, anchor: .trailing)
                    }
                }
            }
        }
        .padding(.bottom, 10)
    }

    private func habitLabel(_ habit: Habit) -> some View {
        Menu {
            Button("编辑习惯", systemImage: "pencil") { editingHabit = habit }
            Button("删除习惯", systemImage: "trash", role: .destructive) { deletingHabit = habit }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Circle().fill(Loom.threadColor(for: habit)).frame(width: 4, height: 4)
                    Text(habit.name)
                        .font(.system(size: labelFontSize, weight: .medium))
                        .foregroundStyle(Loom.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "ellipsis")
                        .font(.system(size: 9, weight: .medium))
                        .rotationEffect(.degrees(90))
                        .foregroundStyle(Loom.secondary)
                }
                Text(habit.scheduleDescription)
                    .font(.system(size: captionFontSize))
                    .foregroundStyle(Loom.secondary)
                    .lineLimit(1)
            }
            .padding(.trailing, 9)
            .frame(width: labelWidth, height: rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel("管理\(habit.name)，\(habit.scheduleDescription)")
        .accessibilityHint("打开编辑与删除菜单")
    }

    private func dateHeader(_ day: Date) -> some View {
        let selected = Calendar.ideabox.isDate(day, inSameDayAs: selectedDate)
        let isToday = Calendar.ideabox.isDateInToday(day)
        let future = day > today
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { weekCursor.select(day) }
        } label: {
            VStack(spacing: 8) {
                Text(["日", "一", "二", "三", "四", "五", "六"][Calendar.ideabox.component(.weekday, from: day) - 1])
                    .font(.system(size: 10))
                    .foregroundStyle(Loom.secondary)
                Text(day.dayNumberTitle)
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(selected ? Loom.paper : Loom.ink)
                    .frame(width: 34, height: 34)
                    .background(selected ? Loom.ink : .clear, in: Circle())
                    .overlay(Circle().stroke(isToday && !selected ? Loom.cobalt : .clear, lineWidth: 1))
            }
            .frame(width: dayWidth, height: columnHeaderHeight)
            .background(alignment: .bottom) {
                if selected { Rectangle().fill(Loom.acid.opacity(0.19)).frame(height: 18) }
            }
            .opacity(future ? 0.35 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .disabled(future)
        .accessibilityLabel(day.fullDayTitle)
        .accessibilityValue(selected ? "已选择" : isToday ? "今天" : "")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func intersection(habit: Habit, day: Date) -> some View {
        let completed = habit.isCompleted(on: day)
        let scheduled = habit.isScheduled(on: day)
        let future = day > today
        let selected = Calendar.ideabox.isDate(day, inSameDayAs: selectedDate)
        return Button {
            let wasCompleted = habit.isCompleted(on: day)
            withAnimation(reduceMotion ? nil : .spring(response: wasCompleted ? 0.3 : 0.48, dampingFraction: 0.69)) {
                weekCursor.select(day)
                appModel.toggleHabit(habit.id, on: day)
            }
            if !wasCompleted { checkInFeedback += 1 }
        } label: {
            ZStack {
                Rectangle().fill(selected ? Loom.acid.opacity(0.19) : .clear)
                Rectangle().fill(Loom.hairline).frame(width: 0.65)
                if scheduled {
                    HabitThreadKnot(completed: completed, color: Loom.threadColor(for: habit))
                        .opacity(future ? 0.28 : 1)
                } else {
                    Rectangle().fill(Loom.secondary.opacity(0.45))
                        .frame(width: 7, height: 1)
                }
            }
            .frame(width: dayWidth, height: rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .disabled(future || !scheduled)
        .accessibilityLabel("\(habit.name)，\(day.fullDayTitle)")
        .accessibilityValue(!scheduled ? "未安排" : future ? "未来日期" : completed ? "已完成" : "未完成")
        .accessibilityHint(!scheduled || future ? "" : completed ? "轻点撤销打卡" : "轻点完成打卡")
        .accessibilityIdentifier("habit-\(habit.id.uuidString)-\(day.dayKey)")
    }

    private func weftLines(color: Color) -> some View {
        Canvas { context, size in
            for offset in [-2.0, 0.0, 2.0] {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: size.height / 2 + offset))
                line.addLine(to: CGPoint(x: size.width, y: size.height / 2 + offset))
                context.stroke(line, with: .color(color.opacity(offset == 0 ? 0.28 : 0.13)), lineWidth: 0.65)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var matrixFootnote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle().fill(Loom.hairline).frame(height: 0.7)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "arrow.left.and.right").font(.system(size: 12))
                Text("左右滑动时间 · 点线结打卡")
                    .font(.system(size: 11))
            }
            .foregroundStyle(Loom.secondary)
            Text(selectionSummary)
                .font(.system(size: 11))
                .foregroundStyle(Loom.secondary)
                .accessibilityIdentifier("habit-selection-summary")
        }
    }

    private var addHabitButton: some View {
        Button { isShowingAddHabit = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus").font(.system(size: 20, weight: .light))
                Text("添加一根线").font(.system(size: 15, weight: .medium))
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 13, weight: .light))
            }
            .foregroundStyle(Loom.ink)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel("添加习惯")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Canvas { context, size in
                for index in 0..<3 {
                    let x = size.width * (0.27 + Double(index) * 0.18)
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addCurve(to: CGPoint(x: x + 12, y: size.height), control1: CGPoint(x: x - 22, y: size.height * 0.4), control2: CGPoint(x: x + 32, y: size.height * 0.58))
                    let colors = [Loom.cobalt, Loom.clay, Loom.secondary]
                    context.stroke(path, with: .color(colors[index].opacity(0.5)), lineWidth: 1)
                }
            }
            .frame(height: 145).padding(.vertical, 20)
            .accessibilityHidden(true)
            Text("先添一根线。")
                .font(.system(size: 24, weight: .medium)).foregroundStyle(Loom.ink)
            Text("一个小习惯，就能开始编织你的日常。")
                .font(.system(size: 13)).foregroundStyle(Loom.secondary)
        }
        .padding(.bottom, 16)
    }

    private func changeWeek(by delta: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24)) {
            weekCursor.synchronize(with: Date())
            weekCursor.move(by: delta)
        }
    }

    private func synchronizeCalendarDay() {
        weekCursor.synchronize(with: Date())
    }

    private func shortDate(_ date: Date) -> String {
        let calendar = Calendar.ideabox
        return String(format: "%02d.%02d", calendar.component(.month, from: date), calendar.component(.day, from: date))
    }
}

/// Keeps the displayed week absolute while the calendar day advances.
/// Browsing history stays in place; a selection following today keeps following it.
private struct HabitWeekCursor {
    private(set) var today: Date
    private(set) var selectedDate: Date
    private(set) var weekStart: Date
    private let calendar: Calendar

    init(today date: Date = Date(), calendar: Calendar = .ideabox) {
        self.calendar = calendar
        let day = calendar.startOfDay(for: date)
        today = day
        selectedDate = day
        weekStart = calendar.dateInterval(of: .weekOfYear, for: day)?.start ?? day
    }

    var days: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var isCurrentWeek: Bool { weekStart == startOfWeek(containing: today) }
    var canAdvanceWeek: Bool { weekStart < startOfWeek(containing: today) }

    mutating func synchronize(with date: Date) {
        let newToday = calendar.startOfDay(for: date)
        guard newToday != today else { return }
        let wasFollowingToday = selectedDate == today && isCurrentWeek
        today = newToday
        if wasFollowingToday || selectedDate > newToday {
            selectedDate = newToday
            weekStart = startOfWeek(containing: newToday)
        }
    }

    mutating func returnToToday(_ date: Date = Date()) {
        today = calendar.startOfDay(for: date)
        selectedDate = today
        weekStart = startOfWeek(containing: today)
    }

    mutating func select(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        guard day <= today, startOfWeek(containing: day) == weekStart else { return }
        selectedDate = day
    }

    mutating func move(by count: Int) {
        guard let targetWeek = calendar.date(byAdding: .weekOfYear, value: count, to: weekStart),
              targetWeek <= startOfWeek(containing: today) else { return }
        let position = min(6, max(0, calendar.dateComponents([.day], from: weekStart, to: selectedDate).day ?? 0))
        guard let targetDay = calendar.date(byAdding: .day, value: position, to: targetWeek) else { return }
        weekStart = targetWeek
        selectedDate = min(targetDay, today)
    }

    private func startOfWeek(containing date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}

private struct HabitThreadKnot: View {
    let completed: Bool
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().fill(Loom.paper)
                .overlay(Circle().stroke(Loom.secondary.opacity(0.5), lineWidth: 1))
                .opacity(completed ? 0 : 1)
            if completed {
                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
                    .frame(width: 19, height: 15)
                    .rotationEffect(.degrees(-18))
                HStack(spacing: 2) {
                    Rectangle().fill(Loom.paper.opacity(0.4)).frame(width: 0.7, height: 12)
                    Rectangle().fill(Loom.paper.opacity(0.4)).frame(width: 0.7, height: 12)
                }
                .rotationEffect(.degrees(39))
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Loom.paper)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .frame(width: 16, height: 16)
        .scaleEffect(completed ? 1.06 : 1)
        .accessibilityHidden(true)
    }
}

struct HabitEditorSheet: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var nameFocused: Bool
    let habit: Habit?
    @State private var name: String
    @State private var icon: HabitIcon
    @State private var frequency: HabitFrequency
    @State private var selectedWeekdays: Set<Int>

    init(habit: Habit? = nil) {
        self.habit = habit
        _name = State(initialValue: habit?.name ?? "")
        _icon = State(initialValue: habit?.icon ?? .bookOpen)
        _frequency = State(initialValue: habit?.frequency ?? .daily)
        _selectedWeekdays = State(initialValue: habit?.activeWeekdays ?? [2, 4, 6])
    }

    private let weekdays = [2, 3, 4, 5, 6, 7, 1]
    private var needsWeekdays: Bool { frequency == .custom || frequency == .weekly }
    private var cannotSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (needsWeekdays && selectedWeekdays.isEmpty)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 25) {
                HStack(alignment: .top, spacing: 16) {
                    StudioSheetHeader(title: habit == nil ? "添一根，日常的线。" : "调一调，这根线。", subtitle: habit == nil ? "从一个小习惯开始，慢慢织成日常。" : "调整名字与节奏，已有的打卡记录会保留。")
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Studio.secondary)
                            .frame(width: 44, height: 44)
                            .background(Studio.line.opacity(0.35), in: Circle())
                    }
                    .buttonStyle(StudioPressStyle())
                    .accessibilityLabel("关闭")
                }
                .padding(.top, 18)

                editorSection("给习惯起个名字") {
                    TextField("例如，读书 20 分钟", text: $name)
                        .font(.system(size: 16))
                        .foregroundStyle(Studio.ink)
                        .padding(.horizontal, 17)
                        .frame(height: 54)
                        .background(Studio.line.opacity(0.24))
                        .overlay(alignment: .bottom) { Rectangle().fill(Studio.secondary).frame(height: 0.7) }
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit { nameFocused = false }
                        .accessibilityLabel("习惯名称")
                }

                editorSection("选一个喜欢的图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                        ForEach(HabitIcon.allCases) { item in
                            Button {
                                withAnimation(reduceMotion ? nil : Studio.spring) { icon = item }
                            } label: {
                                VStack(spacing: 7) {
                                    Image(systemName: item.symbolName)
                                        .font(.system(size: 21, weight: .regular))
                                        .foregroundStyle(icon == item ? Studio.background : Studio.ink)
                                        .frame(width: 44, height: 44)
                                        .background(icon == item ? Studio.ink : Studio.line.opacity(0.24))
                                    Text(item.label)
                                        .font(.system(size: 10, weight: icon == item ? .semibold : .regular))
                                        .foregroundStyle(icon == item ? Studio.ink : Studio.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(StudioPressStyle())
                            .accessibilityLabel(item.label)
                            .accessibilityAddTraits(icon == item ? [.isSelected] : [])
                        }
                    }
                }

                editorSection("找到舒服的节奏") {
                    HStack(spacing: 6) {
                        ForEach(HabitFrequency.allCases) { item in
                            Button { selectFrequency(item) } label: {
                                Text(item.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(frequency == item ? .white : Studio.secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 44)
                                    .background(frequency == item ? Studio.ink : Studio.line.opacity(0.24))
                            }
                            .buttonStyle(StudioPressStyle())
                            .accessibilityAddTraits(frequency == item ? [.isSelected] : [])
                        }
                    }
                }

                if needsWeekdays {
                    editorSection(frequency == .weekly ? "每周在哪一天" : "想在哪几天坚持") {
                        ScrollView(.horizontal, showsIndicators: false) {
                          HStack(spacing: 6) {
                            ForEach(weekdays, id: \.self) { weekday in
                                Button { selectWeekday(weekday) } label: {
                                    Text(["", "日", "一", "二", "三", "四", "五", "六"][weekday])
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 44)
                                        .frame(minHeight: 44)
                                        .foregroundStyle(selectedWeekdays.contains(weekday) ? .white : Studio.secondary)
                                        .background(selectedWeekdays.contains(weekday) ? Studio.accent : Studio.line.opacity(0.24))
                                }
                                .buttonStyle(StudioPressStyle())
                                .accessibilityLabel("周\(["", "日", "一", "二", "三", "四", "五", "六"][weekday])")
                                .accessibilityAddTraits(selectedWeekdays.contains(weekday) ? [.isSelected] : [])
                            }
                          }
                        }
                        Text(selectedWeekdays.isEmpty ? "至少选择一天，就可以开始了。" : (frequency == .weekly ? "每周一次，给自己一份小小的期待。" : "只在选定的日子里，遇见这个小目标。"))
                            .font(.system(size: 11))
                            .foregroundStyle(Studio.secondary)
                            .padding(.top, 3)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Studio.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StudioPrimaryButton(title: habit == nil ? "添上这根线" : "保存新的节奏", disabled: cannotSave, action: save)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 14)
                .background(Studio.background)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Studio.background)
        .presentationCornerRadius(32)
    }

    private func editorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(Studio.secondary)
            content()
        }
    }

    private func selectFrequency(_ value: HabitFrequency) {
        withAnimation(reduceMotion ? nil : Studio.spring) {
            frequency = value
            if value == .weekly { selectedWeekdays = [selectedWeekdays.count == 1 ? (selectedWeekdays.first ?? 1) : 1] }
            if value == .custom && selectedWeekdays.isEmpty { selectedWeekdays = [2, 4, 6] }
        }
    }

    private func selectWeekday(_ weekday: Int) {
        withAnimation(reduceMotion ? nil : Studio.spring) {
            if frequency == .weekly { selectedWeekdays = [weekday] }
            else if selectedWeekdays.contains(weekday) { selectedWeekdays.remove(weekday) }
            else { selectedWeekdays.insert(weekday) }
        }
    }

    private func save() {
        guard !cannotSave else { return }
        nameFocused = false
        let days = needsWeekdays ? selectedWeekdays : nil
        withAnimation(reduceMotion ? nil : Studio.spring) {
            if let habit {
                appModel.updateHabit(habit.id, name: name, icon: icon, frequency: frequency, scheduledWeekdays: days)
            } else {
                appModel.addHabit(name: name, icon: icon, frequency: frequency, scheduledWeekdays: days)
            }
        }
        dismiss()
    }
}
