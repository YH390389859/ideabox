import SwiftUI

/// 月份切换方向
enum MonthTransition {
    case next      // 下一个月
    case previous  // 上一个月
    case none      // 无动画
}

/// 月历网格视图 - 7列x5行的完整月份展示
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date = Date()
    @State private var transitionDirection: MonthTransition = .none
    @State private var isAnimating: Bool = false
    @State private var animationOffset: CGFloat = 0
    @State private var previousMonthDate: Date? = nil
    @State private var nextMonthDate: Date? = nil
    
    // 缓存月份数据，避免动画期间重复计算
    @State private var cachedCurrentMonthDays: [Date?] = []
    @State private var cachedPreviousMonthDays: [Date?] = []
    @State private var cachedNextMonthDays: [Date?] = []
    
    // 手势相关状态
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["一", "二", "三", "四", "五", "六", "日"]
    
    /// 动画时长（缩短以提升流畅度）
    private let animationDuration: Double = 0.25
    
    /// 日历高度（用于计算偏移）
    private let calendarHeight: CGFloat = 280
    
    /// 手势切换阈值（拖动距离超过此值触发切换）
    private let swipeThreshold: CGFloat = 50
    
    /// 判断日期是否在当前显示的月份
    private func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }
    
    /// 当前月份的偏移量（动画偏移 + 拖动偏移）
    private var currentMonthOffset: CGFloat {
        return animationOffset + dragOffset
    }
    
    /// 是否应该显示上一个月
    private var shouldShowPreviousMonth: Bool {
        return (transitionDirection == .previous && isAnimating) || 
               (isDragging && dragOffset > 0)
    }
    
    /// 是否应该显示下一个月
    private var shouldShowNextMonth: Bool {
        return (transitionDirection == .next && isAnimating) || 
               (isDragging && dragOffset < 0)
    }
    
    /// 判断日期是否有事件（这里先用示例数据）
    private func hasEvents(_ date: Date) -> [Color] {
        // TODO: 从实际数据源获取
        let day = calendar.component(.day, from: date)
        
        // 示例：某些日期有事件
        switch day {
        case 2, 9, 16:
            return [.purple, .blue, .green]
        case 6, 7, 8, 13, 14, 15:
            return [.purple]
        case 20, 21, 22, 23, 26, 27, 28, 29, 30, 31:
            return [.purple]
        case 3, 10, 17:
            return [.purple, .blue]
        case 4, 11, 18:
            return [.blue]
        case 5, 12, 19:
            return [.purple, .green]
        case 24, 25:
            return [.purple, .blue, .green]
        default:
            return []
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 月份标题和导航
            monthHeader
            
            // 星期标题
            weekdayHeader
            
            // 日期网格容器 - 使用 ZStack 叠加当前月和过渡月
            ZStack {
                // 当前显示的月份（使用缓存数据）
                cachedMonthGridView(days: cachedCurrentMonthDays, month: displayedMonth)
                    .offset(y: currentMonthOffset)
                
                // 上一个月（在动画或拖动时显示，使用缓存数据）
                if shouldShowPreviousMonth, let prevMonth = previousMonthDate {
                    cachedMonthGridView(days: cachedPreviousMonthDays, month: prevMonth)
                        .offset(y: currentMonthOffset - calendarHeight)
                }
                
                // 下一个月（在动画或拖动时显示，使用缓存数据）
                if shouldShowNextMonth, let nextMonth = nextMonthDate {
                    cachedMonthGridView(days: cachedNextMonthDays, month: nextMonth)
                        .offset(y: currentMonthOffset + calendarHeight)
                }
            }
            .frame(height: calendarHeight)
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDragChanged(value)
                    }
                    .onEnded { value in
                        handleDragEnded(value)
                    }
            )
        }
        .background(Color.white)
        .onAppear {
            // 初始化缓存
            updateMonthCache()
        }
        .onChange(of: displayedMonth) { _ in
            // 月份变化后更新缓存（在动画完成后）
            if !isAnimating {
                updateMonthCache()
            }
        }
    }
    
    /// 使用缓存数据创建月份网格视图（性能优化版本）
    private func cachedMonthGridView(days: [Date?], month: Date) -> some View {
        let monthKey = "\(calendar.component(.year, from: month))-\(calendar.component(.month, from: month))"
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(0..<days.count, id: \.self) { index in
                if let date = days[index] {
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isInCurrentMonth: calendar.isDate(date, equalTo: month, toGranularity: .month),
                        eventColors: hasEvents(date)
                    ) {
                        handleDateSelection(date)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .drawingGroup() // 关键优化：光栅化整个网格视图
        .id(monthKey) // 为每个月份视图添加唯一标识
    }
    
    /// 更新月份数据缓存
    private func updateMonthCache() {
        cachedCurrentMonthDays = monthDaysForDate(displayedMonth)
    }
    
    /// 获取指定月份的所有日期
    private func monthDaysForDate(_ month: Date) -> [Date?] {
        var days: [Date?] = []
        
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return days
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let adjustedFirstWeekday = (firstWeekday + 5) % 7
        
        if adjustedFirstWeekday > 0 {
            if let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart) {
                let previousMonthDaysCount = calendar.range(of: .day, in: .month, for: previousMonthStart)?.count ?? 0
                for day in (previousMonthDaysCount - adjustedFirstWeekday + 1)...previousMonthDaysCount {
                    if let date = calendar.date(bySetting: .day, value: day, of: previousMonthStart) {
                        days.append(date)
                    }
                }
            }
        }
        
        for day in monthRange {
            if let date = calendar.date(bySetting: .day, value: day, of: monthStart) {
                days.append(date)
            }
        }
        
        let remainingDays = 35 - days.count
        if remainingDays > 0 {
            if let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) {
                for day in 1...remainingDays {
                    if let date = calendar.date(bySetting: .day, value: day, of: nextMonthStart) {
                        days.append(date)
                    }
                }
            }
        }
        
        return days
    }
    
    /// 处理日期选择
    private func handleDateSelection(_ date: Date) {
        // 检查是否点击的是上个月或下个月的日期
        if !isInCurrentMonth(date) {
            // 判断是上个月还是下个月
            let comparison = calendar.compare(date, to: displayedMonth, toGranularity: .month)
            
            if comparison == .orderedAscending {
                // 点击的是上个月的日期
                switchToMonth(date, direction: .previous)
            } else if comparison == .orderedDescending {
                // 点击的是下个月的日期
                switchToMonth(date, direction: .next)
            }
        } else {
            // 当前月份的日期，直接选择
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
            }
        }
    }
    
    /// 切换到指定月份
    private func switchToMonth(_ date: Date, direction: MonthTransition) {
        // 如果正在动画中，取消前一个动画
        if isAnimating {
            // 完成当前动画状态
            displayedMonth = previousMonthDate ?? nextMonthDate ?? displayedMonth
            animationOffset = 0
            previousMonthDate = nil
            nextMonthDate = nil
            isAnimating = false
            updateMonthCache()
        }
        
        // 更新选中日期
        selectedDate = date
        
        // 如果启用了减少动画设置，直接切换
        if reduceMotion {
            displayedMonth = date
            updateMonthCache()
            return
        }
        
        // 准备动画 - 预先缓存目标月份数据
        isAnimating = true
        transitionDirection = direction
        animationOffset = 0
        
        // 设置过渡月份并缓存数据
        switch direction {
        case .previous:
            previousMonthDate = date
            cachedPreviousMonthDays = monthDaysForDate(date)
            // 上一个月：向下推动（正偏移）
            // 使用 spring 动画，更接近 iOS 原生效果
            withAnimation(.spring(response: animationDuration, dampingFraction: 0.85, blendDuration: 0)) {
                animationOffset = calendarHeight
            }
        case .next:
            nextMonthDate = date
            cachedNextMonthDays = monthDaysForDate(date)
            // 下一个月：向上推动（负偏移）
            // 使用 spring 动画，更接近 iOS 原生效果
            withAnimation(.spring(response: animationDuration, dampingFraction: 0.85, blendDuration: 0)) {
                animationOffset = -calendarHeight
            }
        case .none:
            break
        }
        
        // 动画完成后更新状态
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            displayedMonth = date
            animationOffset = 0
            previousMonthDate = nil
            nextMonthDate = nil
            isAnimating = false
            transitionDirection = .none
            
            // 更新当前月份缓存
            cachedCurrentMonthDays = cachedPreviousMonthDays.isEmpty ? cachedNextMonthDays : cachedPreviousMonthDays
            cachedPreviousMonthDays = []
            cachedNextMonthDays = []
        }
    }
    
    /// 处理拖动变化
    private func handleDragChanged(_ value: DragGesture.Value) {
        // 如果正在动画中，不响应手势
        guard !isAnimating else { return }
        
        // 如果刚开始拖动，预加载上下月份数据
        if !isDragging {
            isDragging = true
            prepareAdjacentMonths()
        }
        
        // 限制拖动范围，避免拖动过远
        let translation = value.translation.height
        let maxDrag = calendarHeight * 0.4 // 最多拖动 40% 的高度
        dragOffset = max(-maxDrag, min(maxDrag, translation))
    }
    
    /// 处理拖动结束
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard isDragging else { return }
        
        let translation = value.translation.height
        let velocity = value.predictedEndTranslation.height - value.translation.height
        
        // 判断是否应该切换月份
        let shouldSwitch = abs(translation) > swipeThreshold || abs(velocity) > 100
        
        if shouldSwitch {
            if translation > 0 {
                // 向下拖动 - 切换到上一个月
                if let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                    isDragging = false
                    dragOffset = 0
                    switchToMonth(prevMonth, direction: .previous)
                    return
                }
            } else {
                // 向上拖动 - 切换到下一个月
                if let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                    isDragging = false
                    dragOffset = 0
                    switchToMonth(nextMonth, direction: .next)
                    return
                }
            }
        }
        
        // 未达到阈值，回弹到原位置
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            dragOffset = 0
        }
        
        // 延迟清理状态，等待回弹动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isDragging = false
            previousMonthDate = nil
            nextMonthDate = nil
            cachedPreviousMonthDays = []
            cachedNextMonthDays = []
        }
    }
    
    /// 预加载相邻月份的数据
    private func prepareAdjacentMonths() {
        // 预加载上一个月
        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            previousMonthDate = prevMonth
            cachedPreviousMonthDays = monthDaysForDate(prevMonth)
        }
        
        // 预加载下一个月
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            nextMonthDate = nextMonth
            cachedNextMonthDays = monthDaysForDate(nextMonth)
        }
    }
    
    private var monthHeader: some View {
        HStack(spacing: 8) {
            // 左箭头按钮
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "8F9BB3"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "F4F5F7"))
                    .cornerRadius(10)
            }
            
            Spacer()
            
            // 月份和年份
            VStack(spacing: 4) {
                Text(monthString)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "222B45"))
                
                Text(yearString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "8F9BB3"))
            }
            
            Spacer()
            
            // 右箭头按钮
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "8F9BB3"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "F4F5F7"))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "8F9BB3"))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: displayedMonth)
    }
    
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            switchToMonth(newMonth, direction: .previous)
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            switchToMonth(newMonth, direction: .next)
        }
    }
}

/// 日期单元格
private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isInCurrentMonth: Bool
    let eventColors: [Color]
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    private var day: Int {
        calendar.component(.day, from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? Color(hex: "735BF2") : Color.clear)
                    .cornerRadius(10)
                
                // 事件指示器
                if !eventColors.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(0..<min(eventColors.count, 3), id: \.self) { index in
                            Circle()
                                .fill(eventColors[index])
                                .frame(width: 4, height: 4)
                                .overlay(
                                    Circle()
                                        .stroke(eventColors[index].opacity(0.3), lineWidth: 1.2)
                                )
                        }
                    }
                    .frame(height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
            .frame(height: 52)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isInCurrentMonth {
            return Color(hex: "222B45")
        } else {
            return Color(hex: "8F9BB3")
        }
    }
}

// 颜色扩展
private extension Color {
    static let purple = Color(hex: "6D29F6")
    static let blue = Color(hex: "0095FF")
    static let green = Color(hex: "00B383")
}

#Preview {
    MonthCalendarView(selectedDate: .constant(Date()))
}

