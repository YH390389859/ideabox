import SwiftUI

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentWeekOffset: Int = 0
    @State private var isUpdatingFromSwipe: Bool = false
    
    private let dateHelper = DateHelper.shared
    private let calendar = Calendar.current
    
    var body: some View {
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
        .frame(height: 60)
        .background(Color(hex: "FAFAFA"))
        .onAppear {
            // 初始化：定位到今天所在周
            currentWeekOffset = 0
        }
        .onChange(of: currentWeekOffset) { newOffset in
            // 翻周时保持星期几不变（T011）
            isUpdatingFromSwipe = true
            preserveWeekdayOnNavigation(newOffset: newOffset)
            // 延迟重置标志，确保 onChange(of: selectedDate) 能检测到
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isUpdatingFromSwipe = false
            }
        }
        .onChange(of: selectedDate) { newDate in
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

/// 单周显示视图
private struct WeekRowView: View {
    let week: WeekData
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(week.days) { day in
                let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onDateSelected(day.date)
                    }
                }) {
                    VStack(spacing: 1) {
                        Text(day.weekday)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isSelected ? Color.white.opacity(0.9) : Color(hex: "999999"))
                        
                        Text("\(day.day)")
                            .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? Color.white : Color(hex: "333333"))
                    }
                    .frame(width: 38, height: 38)
                    .background(isSelected ? Color(hex: "FF453B") : Color.clear)
                    .cornerRadius(19)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity) // 让每个日期均匀分布
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

#Preview {
    WeekCalendarView(selectedDate: .constant(Date()))
}
