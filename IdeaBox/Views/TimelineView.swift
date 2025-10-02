import SwiftUI

struct TimelineView: View {
    let events: [EventItem]
    
    // 扩展到全天24小时
    let timeSlots = ["00:00", "01:00", "02:00", "03:00", "04:00", "05:00",
                     "06:00", "07:00", "08:00", "09:00", "10:00", "11:00",
                     "12:00", "13:00", "14:00", "15:00", "16:00", "17:00",
                     "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"]
    
    // 基础高度和事件卡片高度
    private let minHourHeight: CGFloat = 60
    private let eventCardHeight: CGFloat = 72
    private let eventSpacing: CGFloat = 8
    
    // 获取按小时分组的事件
    // 例如：12:00-12:59之间的所有事件都属于hour=12这个时间段
    // 返回结果按时间排序（早的在前）
    private func eventsForHour(_ hour: Int) -> [EventItem] {
        events.filter { event in
            let components = event.time.split(separator: ":")
            guard let eventHour = Int(components[0]) else { return false }
            return eventHour == hour  // 例如：12:30、12:45都属于12点这个时段
        }.sorted { $0.time < $1.time }  // 按时间排序
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // 每个时间段作为一个整体（左边时间 + 右边事件容器）
                        ForEach(0..<24, id: \.self) { hour in
                            TimeSlotRow(
                                hour: hour,
                                timeLabel: timeSlots[hour],
                                events: eventsForHour(hour),
                                minHeight: minHourHeight,
                                eventCardHeight: eventCardHeight,
                                eventSpacing: eventSpacing
                            )
                            .id("hour_\(hour)")
                        }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 100) // 额外底部空间，防止内容被导航栏遮挡
            }
            .onAppear {
                    // 滚动到早上8点的位置
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("hour_8", anchor: .top)
                        }
                    }
                }
            }
            
            // 底部固定渐变遮罩（从最底部开始覆盖）
            VStack(spacing: 0) {
                Spacer()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.5),
                        Color.white.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            .allowsHitTesting(false) // 不拦截触摸事件
        }
    }
}

// 时间段行组件：左边时间 + 右边事件容器
struct TimeSlotRow: View {
    let hour: Int
    let timeLabel: String
    let events: [EventItem]
    let minHeight: CGFloat
    let eventCardHeight: CGFloat
    let eventSpacing: CGFloat
    
    // 计算当前时间段的高度
    private var rowHeight: CGFloat {
        if events.isEmpty {
            return minHeight
        }
        // 事件总高度 + 间距 + padding
        let totalEventHeight = CGFloat(events.count) * eventCardHeight
        let totalSpacing = CGFloat(max(0, events.count - 1)) * eventSpacing
        return totalEventHeight + totalSpacing + 20
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 左侧：时间标签
            Text(timeLabel)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "999999"))
                .frame(width: 60, alignment: .leading)
                .padding(.leading, 8)
                .padding(.top, 5)
            
            // 右侧：事件容器
            VStack(alignment: .leading, spacing: eventSpacing) {
                if events.isEmpty {
                    // 没有事件，显示空白占位
                    Color.clear
                        .frame(height: minHeight - 10)
                } else {
                    // 有事件，垂直排列
                    ForEach(events) { event in
                        EventCard(event: event)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 5)
            .padding(.leading, 8)
        }
        .frame(height: rowHeight)
        .overlay(
            // 顶部分隔线
            Divider()
                .background(Color(hex: "EBEBEB")),
            alignment: .top
        )
    }
}

struct EventCard: View {
    let event: EventItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo
            RoundedRectangle(cornerRadius: 10)
                .fill(event.logoColor)
                .frame(width: 48, height: 48)
            
            // 文本内容
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(event.accentColor)
                    .lineLimit(1)
                
                Text(event.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(event.accentColor.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .padding(.leading, 12)
        .frame(width: 320, height: 72)
        .background(event.backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(event.borderColor, lineWidth: 1.5)
        )
    }
}

#Preview {
    // 测试示例：展示不同时间段的高度调整
    TimelineView(events: [
        // 12:00-12:59 时段有2个事件 → 该时段高度会拉高
        EventItem(
            type: .link,
            time: "12:30",
            title: "12:30  苹果官网",
            subtitle: "apple.com",
            backgroundColor: Color(hex: "EDF2FF"),
            borderColor: Color(hex: "007AFF"),
            accentColor: Color(hex: "007AFF"),
            logoColor: Color(hex: "E0E5F2")
        ),
        EventItem(
            type: .link,
            time: "12:55",
            title: "12:55  GitHub",
            subtitle: "github.com",
            backgroundColor: Color(hex: "EDF5FF"),
            borderColor: Color(hex: "0085FF"),
            accentColor: Color(hex: "0085FF"),
            logoColor: Color(hex: "D9E5FF")
        ),
        // 14:00-14:59 时段只有1个事件 → 正常高度
        EventItem(
            type: .textDiary,
            time: "14:20",
            title: "14:20  今天的工作总结",
            subtitle: "完成了三个重要任务，感觉效率很高...",
            backgroundColor: Color(hex: "EDF2FF"),
            borderColor: Color(hex: "007AFF"),
            accentColor: Color(hex: "007AFF"),
            logoColor: Color(hex: "D9E0F2")
        )
    ])
}

