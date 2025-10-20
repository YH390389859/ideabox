import SwiftUI

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentWeekOffset: Int = 0
    @State private var isUpdatingFromSwipe: Bool = false
    
    private let dateHelper = DateHelper.shared
    private let calendar = Calendar.current
    private let daysOfWeek = ["一", "二", "三", "四", "五", "六", "日"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 月份标题（与月历视图样式一致）
            monthHeader
            
            // 星期标题（与月历视图一致）
            weekdayHeader
            
            // 周历内容
            TabView(selection: $currentWeekOffset) {
                ForEach(-52...52, id: \.self) { offset in
                    WeekRowView(
                        week: dateHelper.getWeek(offset: offset),
                        selectedDate: selectedDate,
                        onDateSelected: { date in
                            selectedDate = date
                        }
                    )
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 72)
        }
        .background(Color.white)
        .onAppear {
            // 初始化：定位到今天所在周
            currentWeekOffset = 0
        }
        .onChange(of: currentWeekOffset) { oldValue, newOffset in
            // 翻周时保持星期几不变（T011）
            isUpdatingFromSwipe = true
            preserveWeekdayOnNavigation(newOffset: newOffset)
            // 延迟重置标志，确保 onChange(of: selectedDate) 能检测到
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isUpdatingFromSwipe = false
            }
        }
        .onChange(of: selectedDate) { oldValue, newDate in
            // 如果是翻周导致的日期变化，不需要滚动日历
            guard !isUpdatingFromSwipe else { return }
            
            // 当选中日期变化时（如点击"今天"按钮），检查是否需要切换到对应的周
            let targetOffset = dateHelper.weekOffset(for: newDate, relativeTo: Date())
            if targetOffset != currentWeekOffset {
                withAnimation {
                    currentWeekOffset = targetOffset
                }
            }
        }
    }
    
    /// 月份标题（简化版，与月历视图样式一致）
    private var monthHeader: some View {
        HStack {
            Text(monthString)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("222B45"))
            
            Text(yearString)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color("8F9BB3"))
            
            Spacer()
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }
    
    /// 星期标题行（与月历视图样式一致）
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("8F9BB3"))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 16)
    }
    
    /// 格式化月份字符串
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        return formatter.string(from: selectedDate)
    }
    
    /// 格式化年份字符串
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedDate)
    }
    
    /// 翻周时保持星期几不变的逻辑
    private func preserveWeekdayOnNavigation(newOffset: Int) {
        let currentWeekday = calendar.component(.weekday, from: selectedDate)
        let newWeek = dateHelper.getWeek(offset: newOffset)
        
        // 在新周中找到相同星期几的日期
        if let newDate = newWeek.days.first(where: { day in
            calendar.component(.weekday, from: day.date) == currentWeekday
        }) {
            selectedDate = newDate.date
        }
    }
}

/// 单周显示视图（与月历视图样式一致）
private struct WeekRowView: View {
    let week: WeekData
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    
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
        HStack(spacing: 0) {
            ForEach(week.days) { day in
                let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
                let eventColors = hasEvents(day.date)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onDateSelected(day.date)
                    }
                }) {
                    VStack(spacing: 4) {
                        Text("\(day.day)")
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : Color("222B45"))
                            .frame(width: 30, height: 30)
                            .background(isSelected ? Color("735BF2") : Color.clear)
                            .cornerRadius(10)
                        
                        // 事件指示器（与月历视图一致）
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
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// 颜色扩展（与月历视图一致）
private extension Color {
    static let purple = Color("6D29F6")
    static let blue = Color("0095FF")
    static let green = Color("00B383")
}

#Preview {
    WeekCalendarView(selectedDate: .constant(Date()))
}
