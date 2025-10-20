import SwiftUI

/// 可折叠的日历视图 - 在月视图和周视图之间切换
struct CollapsibleCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    
    // 周视图高度（月份标题 44 + 星期标题 30 + 日期行 72）
    private let weekViewHeight: CGFloat = 146
    // 月视图高度（包含月份标题 + 星期标题 + 5行日期）
    private let monthViewHeight: CGFloat = 400
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack(alignment: .top) {
            // 月视图
            if viewMode == .month {
                MonthCalendarView(selectedDate: $selectedDate)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // 周视图
            if viewMode == .week {
                WeekCalendarView(selectedDate: $selectedDate)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(height: viewMode == .month ? monthViewHeight : weekViewHeight)
        .animation(
            reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.8),
            value: viewMode
        )
        .clipped()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDate = Date()
        @State private var viewMode: CalendarViewMode = .month
        
        var body: some View {
            VStack {
                CollapsibleCalendarView(
                    selectedDate: $selectedDate,
                    viewMode: $viewMode
                )
                
                HStack {
                    Button("月视图") {
                        viewMode = .month
                    }
                    Button("周视图") {
                        viewMode = .week
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    return PreviewWrapper()
}

