import SwiftUI

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false
    @State private var selectedTab: NavigationTab = .calendar
    
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
        ZStack(alignment: .bottom) {
            // 主内容区域
            VStack(spacing: 0) {
                // 月历网格视图
                MonthCalendarView(selectedDate: $selectedDate)
                
                // 分隔线
                Rectangle()
                    .fill(Color(hex: "CED3DE").opacity(0.5))
                    .frame(height: 4)
                    .padding(.horizontal, 178)
                
                // 事件列表
                EventListView(events: events)
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
