import SwiftUI

/// 底部导航项枚举
enum NavigationTab {
    case calendar
    case search
    case add // 中央按钮
    case notifications
    case profile
}

struct BottomNavigationBar: View {
    @Binding var selectedTab: NavigationTab
    @Binding var showingAddSheet: Bool
    
    var body: some View {
        ZStack {
            // 底部白色背景容器
            VStack(spacing: 0) {
                // 顶部分隔线
                Rectangle()
                    .fill(Color(hex: "CED3DE").opacity(0.5))
                    .frame(height: 0.5)
                
                // 导航栏内容
                HStack(spacing: 0) {
                    // 日历图标
                    navButton(
                        icon: "calendar",
                        tab: .calendar,
                        isSelected: selectedTab == .calendar
                    )
                    
                    Spacer()
                    
                    // 搜索图标
                    navButton(
                        icon: "magnifyingglass",
                        tab: .search,
                        isSelected: selectedTab == .search
                    )
                    
                    Spacer()
                    
                    // 中央占位（为浮动按钮留空）
                    Color.clear
                        .frame(width: 60)
                    
                    Spacer()
                    
                    // 通知图标
                    navButton(
                        icon: "bell",
                        tab: .notifications,
                        isSelected: selectedTab == .notifications
                    )
                    
                    Spacer()
                    
                    // 个人中心图标
                    navButton(
                        icon: "person",
                        tab: .profile,
                        isSelected: selectedTab == .profile
                    )
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 12)
                .frame(height: 64)
            }
            .background(
                ZStack {
                    // 底部白色背景
                    Color.white
                    
                    // 顶部圆角效果（使用自定义形状）
                    TopRoundedRectangle(radius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: -3)
                }
            )
            
            // 中央浮动添加按钮
            VStack {
                Button(action: {
                    showingAddSheet = true
                }) {
                    ZStack {
                        // 外圈阴影
                        Circle()
                            .fill(Color(hex: "735BF2"))
                            .frame(width: 51, height: 51)
                            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 3)
                        
                        // 加号图标
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -5) // 向上偏移，让按钮浮动
                
                Spacer()
            }
        }
        .frame(height: 92)
    }
    
    private func navButton(icon: String, tab: NavigationTab, isSelected: Bool) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: "735BF2") : Color(hex: "8F9BB3"))
                .frame(width: 44, height: 44)
        }
    }
}

/// 顶部圆角矩形（用于导航栏）
struct TopRoundedRectangle: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 从左上角开始
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        
        // 左上圆角
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        
        // 顶部直线到右上角
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        
        // 右上圆角
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // 右侧直线
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        // 底部直线
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        // 左侧直线回到起点
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Previews

#Preview("Standard - Light Mode") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack {
            Spacer()
            BottomNavigationBar(
                selectedTab: .constant(.calendar),
                showingAddSheet: .constant(false)
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Search Tab Selected") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack {
            Spacer()
            BottomNavigationBar(
                selectedTab: .constant(.search),
                showingAddSheet: .constant(false)
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack {
            Spacer()
            BottomNavigationBar(
                selectedTab: .constant(.calendar),
                showingAddSheet: .constant(false)
            )
        }
    }
    .preferredColorScheme(.dark)
}
