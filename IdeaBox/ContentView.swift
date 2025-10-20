import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false
    @State private var selectedTab: NavigationTab = .calendar
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var scrollOffset: CGFloat = 0
    @State private var isTransitioning: Bool = false // 标记正在进行视图切换
    
    // 滚动阈值（向上滚动多少距离后触发收缩）
    private let scrollThreshold: CGFloat = 50
    
    // 示例事件数据（匹配 Figma 设计）
    let events: [EventItem] = [
        EventItem(
            title: "Design new UX flow for Michael",
            description: "Start from screen 16",
            startTime: "10:00",
            endTime: "13:00",
            colorType: .green,
            date: Date()
        ),
        EventItem(
            title: "Design new UX flow for Michael",
            description: "Start from screen 16",
            startTime: "10:00",
            endTime: "13:00",
            colorType: .green,
            date: Date()
        ),
        EventItem(
            title: "Design new UX flow for Michael",
            description: "Start from screen 16",
            startTime: "10:00",
            endTime: "13:00",
            colorType: .green,
            date: Date()
        ),
        EventItem(
            title: "Brainstorm with the team",
            description: "Define the problem or question that.. View more\nthe brainstorming session will aim to address. The question should be clear and concise.",
            startTime: "14:00",
            endTime: "15:00",
            colorType: .purple,
            date: Date()
        ),
        EventItem(
            title: "Workout with Ella",
            description: "We will do the legs and back workout",
            startTime: "19:00",
            endTime: "20:00",
            colorType: .blue,
            date: Date()
        )
    ]
    
    var body: some View {
        Group {
            if appState.isCheckingAuth {
                // 加载状态
                ProgressView("检查登录状态...")
            } else if appState.isAuthenticated {
                // 已登录 - 显示主界面
                mainView
            } else {
                // 未登录 - 显示登录界面
                AuthenticationView()
                    .onAppear {
                        // 监听登录成功事件
                        NotificationCenter.default.addObserver(
                            forName: NSNotification.Name("UserDidLogin"),
                            object: nil,
                            queue: .main
                        ) { _ in
                            appState.checkAuthStatus()
                        }
                    }
            }
        }
    }
    
    private var mainView: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            VStack(spacing: 0) {
                // 可折叠的日历视图
                CollapsibleCalendarView(
                    selectedDate: $selectedDate,
                    viewMode: $calendarViewMode
                )
                
                // 分隔线
                Rectangle()
                    .fill(Color(hex: "CED3DE").opacity(0.5))
                    .frame(height: 4)
                    .padding(.horizontal, 178)
                
                // 带滚动监听的事件列表
                ScrollView {
                    VStack(spacing: 0) {
                        // 滚动偏移检测器（放在最顶部）
                        Color.clear
                            .frame(height: 0)
                            .onScrollOffsetChange { offset in
                                handleScrollOffset(offset)
                            }
                        
                        EventListView(events: events)
                    }
                }
                .scrollDisabled(isTransitioning) // 在视图切换时禁用滚动
                .coordinateSpace(name: "scroll")
            }
            .background(Color.white)
            
            // 底部导航栏（叠加在内容上方）
            VStack(spacing: 0) {
                Spacer()
                
                BottomNavigationBar(	
                    selectedTab: $selectedTab,
                    showingAddSheet: $showingAddSheet
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showingAddSheet) {
            // TODO: 添加事件的表单视图
            Text("Add Event Sheet")
                .presentationDetents([.medium])
        }
    }
    
    /// 处理滚动偏移，根据滚动方向和位置切换日历视图模式
    private func handleScrollOffset(_ offset: CGFloat) {
        // 如果正在进行视图切换，忽略滚动偏移变化，避免抖动
        guard !isTransitioning else {
            return
        }
        
        // 向上滚动时，offset 变成负数（越滚越小）
        // 当滚动超过阈值时，切换到周视图
        if offset < -scrollThreshold && calendarViewMode == .month {
            isTransitioning = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                calendarViewMode = .week
            }
            // 动画完成后重置标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTransitioning = false
            }
        }
        // 向下滚动回到顶部时（offset 接近 0），切换回月视图
        else if offset > -10 && calendarViewMode == .week {
            isTransitioning = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                calendarViewMode = .month
            }
            // 动画完成后重置标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTransitioning = false
            }
        }
        
        scrollOffset = offset
    }
}

// 扩展用于十六进制颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
