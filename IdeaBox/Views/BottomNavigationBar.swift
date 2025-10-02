import SwiftUI

struct BottomNavigationBar: View {
    // MARK: - Bindings
    
    @Binding var selectedDate: Date
    @Binding var showingAddSheet: Bool
    let onTodayTapped: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    // MARK: - Style & Adapter
    
    private let style = AppleNavigationBarStyle()
    
    private var adapter: AppearanceAdapter {
        AppearanceAdapter()
            .adaptToColorScheme(colorScheme)
            .adaptToDynamicType(sizeCategory)
            .adaptToReduceMotion(reduceMotion)
    }
    
    // MARK: - Scaled Metrics
    
    @ScaledMetric private var iconSize: CGFloat = 22
    @ScaledMetric private var buttonSize: CGFloat = 44
    
    // MARK: - Computed Properties
    
    /// 当前选中的日期是否是今天
    private var isTodaySelected: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    /// 是否应该显示"今天"按钮
    /// 规则：选中今天时隐藏，选中其他日期时显示
    private var shouldShowTodayButton: Bool {
        !isTodaySelected
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: style.buttonSpacing) {
            // 今天按钮（条件显示）
            if shouldShowTodayButton {
                todayButton
                    .transition(reduceMotion ? .identity : .opacity)
            }
            
            Spacer()
            
            // 右侧按钮组
            actionButtons
        }
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, style.verticalPadding)
        .frame(height: style.barHeight)
        .background {
            if reduceTransparency {
                Color.white.opacity(style.backgroundOpacity)
            } else {
                style.backgroundMaterial
            }
        }
        .animation(
            reduceMotion ? .linear(duration: 0.1) : style.animationCurve,
            value: shouldShowTodayButton
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("底部导航栏")
    }
    
    // MARK: - Subviews
    
    /// 今天按钮
    private var todayButton: some View {
        Button(action: {
            HapticManager.shared.trigger(.medium)
            onTodayTapped()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: iconSize))
                Text("今天")
                    .font(.body)
            }
            .foregroundColor(style.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(style.buttonBackgroundColor)
            .cornerRadius(style.buttonCornerRadius)
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: style.shadowOffset.width,
                y: style.shadowOffset.height
            )
        }
        .frame(minWidth: buttonSize, minHeight: buttonSize)
        .accessibilityLabel("今天按钮")
        .accessibilityHint("轻点两下跳转到今天")
    }
    
    /// 右侧操作按钮组
    private var actionButtons: some View {
        HStack(spacing: style.buttonSpacing) {
            // 添加按钮
            Button(action: {
                HapticManager.shared.trigger(.medium)
                showingAddSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(style.accentColor)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .accessibilityLabel("添加按钮")
            .accessibilityHint("轻点两下创建新事项")
            
            // 个人中心按钮
            Button(action: {
                HapticManager.shared.trigger(.light)
                // 导航到个人页面
            }) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(.secondary)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .accessibilityLabel("个人中心按钮")
            .accessibilityHint("轻点两下查看个人信息")
        }
        .padding(10)
        .background(style.buttonBackgroundColor)
        .cornerRadius(style.buttonCornerRadius)
        .shadow(
            color: style.shadowColor,
            radius: style.shadowRadius,
            x: style.shadowOffset.width,
            y: style.shadowOffset.height
        )
    }
}

// MARK: - Previews

#Preview("Standard - Light Mode") {
    BottomNavigationBar(
        selectedDate: .constant(Date()),
        showingAddSheet: .constant(false),
        onTodayTapped: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Today Button Visible") {
    BottomNavigationBar(
        selectedDate: .constant(Calendar.current.date(byAdding: .day, value: 1, to: Date())!),
        showingAddSheet: .constant(false),
        onTodayTapped: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    BottomNavigationBar(
        selectedDate: .constant(Date()),
        showingAddSheet: .constant(false),
        onTodayTapped: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Large Font") {
    BottomNavigationBar(
        selectedDate: .constant(Date()),
        showingAddSheet: .constant(false),
        onTodayTapped: {}
    )
    .environment(\.sizeCategory, .extraExtraExtraLarge)
}
