import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedDate: Date
    @Binding var showingAddSheet: Bool
    let onTodayTapped: () -> Void
    
    // MARK: - TodayButtonController Implementation
    
    /// 当前选中的日期是否是今天
    private var isTodaySelected: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    /// 是否应该显示"今天"按钮
    /// 规则：选中今天时隐藏，选中其他日期时显示
    private var shouldShowTodayButton: Bool {
        !isTodaySelected
    }
    
    var body: some View {
        HStack {
            // 今天按钮（条件显示）
            if shouldShowTodayButton {
                Button(action: {
                    onTodayTapped()
                }) {
                    Text("今天")
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "007AFF"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(19)
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                }
                .transition(.opacity)
            }
            
            Spacer()
            
            // 右侧按钮组
            HStack(spacing: 12) {
                // 添加按钮
                Button(action: {
                    showingAddSheet = true
                }) {
                    Text("+")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color(hex: "007AFF"))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .cornerRadius(18)
                }
                
                // 我的按钮
                Button(action: {
                    // 导航到个人页面
                }) {
                    Text("👤")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "666666"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "E6E6E6"))
                        .cornerRadius(18)
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(19)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 25)
        .frame(height: 84)
        .background(Color.white.opacity(0.95))
        .animation(.easeInOut(duration: 0.2), value: shouldShowTodayButton)
    }
}

#Preview {
    BottomNavigationBar(
        selectedDate: .constant(Date()),
        showingAddSheet: .constant(false),
        onTodayTapped: {}
    )
}
