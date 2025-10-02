import SwiftUI

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false
    
    let events: [EventItem] = [
        EventItem(
            type: .textDiary,
            time: "07:30",
            title: "07:30  晨间日记",
            subtitle: "今天是个好天气，准备开始新的一天...",
            backgroundColor: Color(hex: "EDF2FF"),
            borderColor: Color(hex: "007AFF"),
            accentColor: Color(hex: "007AFF"),
            logoColor: Color(hex: "D9E0F2")
        ),
        EventItem(
            type: .link,
            time: "09:15",
            title: "09:15  GitHub - SwiftUI 教程",
            subtitle: "github.com",
            backgroundColor: Color(hex: "EDF5FF"),
            borderColor: Color(hex: "0085FF"),
            accentColor: Color(hex: "0085FF"),
            logoColor: Color(hex: "D9E5FF")
        ),
        EventItem(
            type: .link,
            time: "12:55",
            title: "12:55  苹果官网 - iPhone 15 Pro",
            subtitle: "apple.com",
            backgroundColor: Color(hex: "EDF2FF"),
            borderColor: Color(hex: "007AFF"),
            accentColor: Color(hex: "007AFF"),
            logoColor: Color(hex: "E0E5F2")
        ),
        EventItem(
            type: .textDiary,
            time: "14:20",
            title: "14:20  今天的工作总结",
            subtitle: "完成了三个重要任务，感觉效率很高...",
            backgroundColor: Color(hex: "EDF2FF"),
            borderColor: Color(hex: "007AFF"),
            accentColor: Color(hex: "007AFF"),
            logoColor: Color(hex: "D9E0F2")
        ),
        EventItem(
            type: .voiceDiary,
            time: "15:45",
            title: "15:45  周末计划",
            subtitle: "想去爬山，然后约朋友吃饭...",
            backgroundColor: Color(hex: "EDF2FF"),
            borderColor: Color(hex: "007AFF"),
            accentColor: Color(hex: "007AFF"),
            logoColor: Color(hex: "D9E0F2")
        ),
        EventItem(
            type: .link,
            time: "16:30",
            title: "16:30  小红书",
            subtitle: "秋日穿搭分享 | 温柔又显白的配色...",
            backgroundColor: Color(hex: "FFF2F5"),
            borderColor: Color(hex: "FF2442"),
            accentColor: Color(hex: "FF2442"),
            logoColor: Color(hex: "FFE0E5")
        ),
        EventItem(
            type: .link,
            time: "17:15",
            title: "17:15  知乎",
            subtitle: "AI设计工具对比：Figma vs Sketch...",
            backgroundColor: Color(hex: "EDF5FF"),
            borderColor: Color(hex: "0085FF"),
            accentColor: Color(hex: "0085FF"),
            logoColor: Color(hex: "D9E5FF")
        ),
        EventItem(
            type: .textDiary,
            time: "20:30",
            title: "20:30  晚间反思",
            subtitle: "今天收获满满，明天继续加油...",
            backgroundColor: Color(hex: "EDF2FF"),
            borderColor: Color(hex: "007AFF"),
            accentColor: Color(hex: "007AFF"),
            logoColor: Color(hex: "D9E0F2")
        )
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            VStack(spacing: 0) {
                // 周日历（iOS 风格分页）
                WeekCalendarView(selectedDate: $selectedDate)
                
                // 日期标题
                DateHeaderView(selectedDate: selectedDate)
                
                // 时间轴容器
                TimelineView(events: events)
                
                Spacer()
            }
            .background(Color.white)
            .overlay(
                // 底部渐变遮罩，让内容和导航栏过渡更自然
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false), // 不拦截触摸事件
                alignment: .bottom
            )
            
            // 底部导航栏（叠加在内容上方）
            VStack(spacing: 0) {
                Spacer()
                
                BottomNavigationBar(
                    selectedDate: $selectedDate,
                    showingAddSheet: $showingAddSheet,
                    onTodayTapped: {
                        jumpToToday()
                    }
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onChange(of: selectedDate) { _ in
            // 当选中日期变化时，可以在这里加载该日期的事件数据
        }
    }
    
    /// 跳转到今天
    private func jumpToToday() {
        selectedDate = Date()
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
