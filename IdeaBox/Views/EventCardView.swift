import SwiftUI

/// 事件卡片视图 - 匹配 Figma 设计
struct EventCardView: View {
    let event: EventItem
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧彩色时间标签
            timeLabel
            
            // 主要内容区域
            VStack(alignment: .leading, spacing: 8) {
                // 标题
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "222B45"))
                    .lineLimit(2)
                
                // 描述（如果有）
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "8F9BB3"))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.leading, 14)
            .padding(.trailing, 14)
            .padding(.vertical, 12)
            
            Spacer()
            
            // 右侧菜单按钮
            menuButton
        }
        .frame(height: 95)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 3)
    }
    
    private var timeLabel: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 时钟图标
            ZStack {
                Circle()
                    .fill(event.colorType.color)
                    .frame(width: 10, height: 10)
                
                // 外圈（可选，如果需要边框效果）
                Circle()
                    .stroke(event.colorType.color.opacity(0.3), lineWidth: 1.2)
                    .frame(width: 10, height: 10)
            }
            .padding(.bottom, 2)
            
            // 时间文本
            Text(event.timeRange)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "8F9BB3"))
                .rotationEffect(.degrees(-90))
                .fixedSize()
            
            Spacer()
        }
        .frame(width: 14)
        .padding(.leading, 14)
    }
    
    private var menuButton: some View {
        VStack(spacing: 0) {
            Button(action: {
                // TODO: 显示菜单选项
            }) {
                VStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(Color(hex: "8F9BB3"))
                            .frame(width: 3, height: 3)
                    }
                }
                .padding(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.trailing, 14)
        .padding(.top, 16)
    }
}

/// 事件列表视图
struct EventListView: View {
    let events: [EventItem]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(events) { event in
                    EventCardView(event: event)
                }
            }
            .padding(.horizontal, 17)
            .padding(.top, 16)
            .padding(.bottom, 120) // 为底部导航栏留出空间
        }
        .background(Color.white)
    }
}

#Preview {
    VStack {
        EventCardView(
            event: EventItem(
                title: "Design new UX flow for Michael",
                description: "Start from screen 16",
                startTime: "10:00",
                endTime: "13:00",
                colorType: .green,
                date: Date()
            )
        )
        .padding()
        
        EventCardView(
            event: EventItem(
                title: "Brainstorm with the team",
                description: "Define the problem or question that.. View more\nthe brainstorming session will aim to address. The question should be clear and concise.",
                startTime: "14:00",
                endTime: "15:00",
                colorType: .purple,
                date: Date()
            )
        )
        .padding()
        
        EventCardView(
            event: EventItem(
                title: "Workout with Ella",
                description: "We will do the legs and back workout",
                startTime: "19:00",
                endTime: "20:00",
                colorType: .blue,
                date: Date()
            )
        )
        .padding()
    }
}

