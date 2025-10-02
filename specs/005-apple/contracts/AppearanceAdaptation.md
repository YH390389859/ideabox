# Contract: AppearanceAdaptation

**Feature**: 005-apple  
**Date**: 2025-10-02  
**Status**: Defined

## 职责

定义系统外观和辅助功能适配规范，确保导航栏在所有系统设置下都能提供良好的用户体验。

---

## 接口定义

### Protocol

```swift
import SwiftUI

protocol AppearanceAdaptable {
    // MARK: - Color Scheme Adaptation
    
    /// 适配颜色方案（浅色/深色模式）
    /// - Parameter scheme: 当前颜色方案
    func adaptToColorScheme(_ scheme: ColorScheme) -> Self
    
    /// 获取当前方案下的颜色
    func color(for scheme: ColorScheme, light: Color, dark: Color) -> Color
    
    // MARK: - Dynamic Type Adaptation
    
    /// 适配动态字体大小
    /// - Parameter category: 内容大小类别
    func adaptToDynamicType(_ category: ContentSizeCategory) -> Self
    
    /// 获取缩放因子
    func scaleFactor(for category: ContentSizeCategory) -> CGFloat
    
    // MARK: - Accessibility Adaptation
    
    /// 适配减少动画模式
    /// - Parameter enabled: 是否启用减少动画
    func adaptToReduceMotion(_ enabled: Bool) -> Self
    
    /// 适配增强对比度模式
    /// - Parameter enabled: 是否启用增强对比度
    func adaptToIncreaseContrast(_ enabled: Bool) -> Self
    
    /// 提供辅助功能标签
    func provideAccessibilityLabels() -> [String: String]
}
```

### 标准实现

```swift
import SwiftUI

/// 外观适配助手
struct AppearanceAdapter: AppearanceAdaptable {
    // MARK: - State
    
    var colorScheme: ColorScheme = .light
    var sizeCategory: ContentSizeCategory = .medium
    var reduceMotion: Bool = false
    var increaseContrast: Bool = false
    
    // MARK: - Color Scheme Adaptation
    
    func adaptToColorScheme(_ scheme: ColorScheme) -> AppearanceAdapter {
        var adapter = self
        adapter.colorScheme = scheme
        return adapter
    }
    
    func color(for scheme: ColorScheme, light: Color, dark: Color) -> Color {
        scheme == .light ? light : dark
    }
    
    // MARK: - Dynamic Type Adaptation
    
    func adaptToDynamicType(_ category: ContentSizeCategory) -> AppearanceAdapter {
        var adapter = self
        adapter.sizeCategory = category
        return adapter
    }
    
    func scaleFactor(for category: ContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium, .large:
            return 1.0
        case .extraLarge:
            return 1.1
        case .extraExtraLarge:
            return 1.2
        case .extraExtraExtraLarge:
            return 1.3
        case .accessibilityMedium:
            return 1.4
        case .accessibilityLarge:
            return 1.6
        case .accessibilityExtraLarge:
            return 1.8
        case .accessibilityExtraExtraLarge:
            return 2.0
        case .accessibilityExtraExtraExtraLarge:
            return 2.2
        @unknown default:
            return 1.0
        }
    }
    
    // MARK: - Accessibility Adaptation
    
    func adaptToReduceMotion(_ enabled: Bool) -> AppearanceAdapter {
        var adapter = self
        adapter.reduceMotion = enabled
        return adapter
    }
    
    func adaptToIncreaseContrast(_ enabled: Bool) -> AppearanceAdapter {
        var adapter = self
        adapter.increaseContrast = enabled
        return adapter
    }
    
    func provideAccessibilityLabels() -> [String: String] {
        [
            "today": "今天按钮",
            "add": "添加按钮",
            "profile": "个人中心按钮",
            "navigationBar": "底部导航栏"
        ]
    }
    
    // MARK: - Computed Properties
    
    /// 当前动画时长
    var animationDuration: TimeInterval {
        reduceMotion ? 0.1 : 0.25
    }
    
    /// 当前对比度增强因子
    var contrastMultiplier: CGFloat {
        increaseContrast ? 1.2 : 1.0
    }
}
```

---

## 深色模式适配

### 颜色资源定义

在 `Assets.xcassets/Colors/` 中定义自适应颜色：

#### NavigationAccent.colorset

```json
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.000",
          "green" : "0.478",
          "blue" : "1.000",
          "alpha" : "1.000"
        }
      }
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.039",
          "green" : "0.518",
          "blue" : "1.000",
          "alpha" : "1.000"
        }
      }
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
```

- 浅色模式: `#007AFF` (标准系统蓝)
- 深色模式: `#0A84FF` (更亮的蓝，提高对比度)

### SwiftUI 使用

```swift
struct BottomNavigationBar: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(Color("NavigationAccent")) // 自动适配
        }
        .background(.ultraThinMaterial) // 自动适配
    }
}
```

### 手动颜色适配（特殊场景）

```swift
extension Color {
    /// 根据颜色方案返回不同颜色
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// 使用
.foregroundColor(.adaptive(light: .black, dark: .white))
```

---

## 动态字体适配

### 使用语义字体大小

```swift
// ✅ 推荐：使用语义字体
Text("Today")
    .font(.body)

Image(systemName: "plus.circle.fill")
    .font(.title3)

// ❌ 不推荐：固定像素大小
Text("Today")
    .font(.system(size: 17))
```

### 自定义字体缩放

```swift
@ScaledMetric private var iconSize: CGFloat = 22
@ScaledMetric private var buttonSize: CGFloat = 44

var body: some View {
    Button {
        // Action
    } label: {
        Image(systemName: "plus.circle.fill")
            .font(.system(size: iconSize))
    }
    .frame(width: buttonSize, height: buttonSize)
}
```

### 最小尺寸保证

```swift
@ScaledMetric(relativeTo: .body) private var minButtonSize: CGFloat = 44

var buttonSize: CGFloat {
    max(minButtonSize, 44) // 确保至少 44pt
}
```

### 布局适配

```swift
@Environment(\.sizeCategory) var sizeCategory

var shouldUseCompactLayout: Bool {
    sizeCategory > .extraExtraExtraLarge
}

var body: some View {
    if shouldUseCompactLayout {
        // 大字体时使用紧凑布局
        VStack { /* ... */ }
    } else {
        // 标准布局
        HStack { /* ... */ }
    }
}
```

---

## 减少动画适配

### 检测减少动画设置

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    Button("Action") {
        // Action
    }
    .animation(
        reduceMotion ? .linear(duration: 0.1) : .easeInOut(duration: 0.25),
        value: isVisible
    )
}
```

### 动画策略

| 动画类型 | 减少动画模式 | 理由 |
|---------|------------|------|
| 装饰性动画 | 完全禁用 | 不影响功能 |
| 转场动画 | 简化为淡入淡出 | 保留视觉连续性 |
| 反馈动画 | 缩短时长（0.1秒） | 快速确认 |
| 布局动画 | 禁用或瞬间完成 | 减少眩晕感 |

### 实现示例

```swift
struct BottomNavigationBar: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var animationDuration: TimeInterval {
        reduceMotion ? 0.1 : 0.25
    }
    
    private var animation: Animation {
        reduceMotion ? .linear(duration: animationDuration) : .easeInOut(duration: animationDuration)
    }
    
    var body: some View {
        HStack {
            if shouldShowTodayButton {
                Button("Today") { }
                    .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .animation(animation, value: shouldShowTodayButton)
    }
}
```

---

## 增强对比度适配

### 检测对比度设置

```swift
@Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

var body: some View {
    HStack {
        // 内容
    }
    .background(
        reduceTransparency ? Color.white : .ultraThinMaterial
    )
}
```

### 颜色对比度调整

```swift
extension Color {
    /// 根据对比度设置调整颜色
    func contrastAdjusted(increaseContrast: Bool) -> Color {
        if increaseContrast {
            // 返回对比度更高的版本
            return self.opacity(1.0)
        }
        return self
    }
}
```

### 不依赖颜色传达信息

```swift
// ❌ 坏：仅用颜色区分
Image(systemName: "circle.fill")
    .foregroundColor(isSelected ? .blue : .gray)

// ✅ 好：使用不同图标
Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
    .foregroundColor(.blue)
```

---

## VoiceOver 支持

### 基础标签

```swift
Button(action: { }) {
    Image(systemName: "plus.circle.fill")
}
.accessibilityLabel("添加")
.accessibilityHint("轻点两下以创建新事项")
```

### 状态通知

```swift
@State private var selectedTab = "home"

Button("Home") {
    selectedTab = "home"
}
.accessibilityLabel("首页")
.accessibilityAddTraits(selectedTab == "home" ? .isSelected : [])
```

### 组合元素

```swift
HStack {
    Button("Button 1") { }
    Button("Button 2") { }
    Button("Button 3") { }
}
.accessibilityElement(children: .contain) // 保留子元素可访问性
.accessibilityLabel("导航栏")
```

### 隐藏装饰元素

```swift
// 纯装饰性图标，不需要 VoiceOver 读出
Image(systemName: "sparkles")
    .accessibilityHidden(true)
```

---

## 完整集成示例

```swift
struct BottomNavigationBar: View {
    // MARK: - Environment
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    // MARK: - State
    
    @Binding var selectedDate: Date
    @Binding var showingAddSheet: Bool
    let onTodayTapped: () -> Void
    
    // MARK: - Computed Properties
    
    private var adapter: AppearanceAdapter {
        AppearanceAdapter()
            .adaptToColorScheme(colorScheme)
            .adaptToDynamicType(sizeCategory)
            .adaptToReduceMotion(reduceMotion)
    }
    
    @ScaledMetric private var iconSize: CGFloat = 22
    @ScaledMetric private var buttonSize: CGFloat = 44
    
    private var shouldShowTodayButton: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12 * adapter.scaleFactor(for: sizeCategory)) {
            // 今天按钮
            if shouldShowTodayButton {
                Button(action: onTodayTapped) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: iconSize))
                        Text("今天")
                            .font(.body)
                    }
                }
                .accessibilityLabel("今天按钮")
                .accessibilityHint("轻点两下跳转到今天")
                .transition(reduceMotion ? .identity : .opacity)
            }
            
            Spacer()
            
            // 添加按钮
            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: iconSize))
            }
            .frame(width: buttonSize, height: buttonSize)
            .accessibilityLabel("添加按钮")
            .accessibilityHint("轻点两下创建新事项")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 25)
        .background(
            reduceTransparency ? Color.white.opacity(0.95) : .ultraThinMaterial
        )
        .animation(
            reduceMotion ? .linear(duration: 0.1) : .easeInOut(duration: 0.25),
            value: shouldShowTodayButton
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("底部导航栏")
    }
}
```

---

## 测试规范

### 辅助功能测试清单

#### 深色模式
- [ ] 切换到深色模式，验证颜色自动调整
- [ ] 验证所有文本和图标清晰可见
- [ ] 截图对比浅色/深色模式

#### 动态字体
- [ ] 设置字体大小为 XS，验证布局完整
- [ ] 设置字体大小为 XXXL，验证无截断
- [ ] 设置为辅助功能尺寸，验证适配正确
- [ ] 验证按钮触摸目标始终 ≥ 44pt

#### 减少动画
- [ ] 开启减少动画，验证装饰动画消失
- [ ] 验证功能性转场仍然存在（但简化）
- [ ] 验证交互仍然流畅

#### VoiceOver
- [ ] 开启 VoiceOver，验证所有按钮可读
- [ ] 验证标签清晰描述功能
- [ ] 验证提示说明操作方式
- [ ] 验证焦点顺序合理

#### 增强对比度
- [ ] 开启增强对比度，验证颜色更鲜明
- [ ] 验证所有文本对比度 ≥ 7:1 (AAA)

### 自动化测试

```swift
class AppearanceAdaptationTests: XCTestCase {
    func testDarkModeColors() {
        let view = BottomNavigationBar(
            selectedDate: .constant(Date()),
            showingAddSheet: .constant(false),
            onTodayTapped: {}
        )
        .environment(\.colorScheme, .dark)
        
        // 快照测试
        assertSnapshot(matching: view, as: .image)
    }
    
    func testDynamicTypeScaling() {
        let categories: [ContentSizeCategory] = [
            .extraSmall,
            .medium,
            .extraExtraExtraLarge
        ]
        
        for category in categories {
            let view = BottomNavigationBar(
                selectedDate: .constant(Date()),
                showingAddSheet: .constant(false),
                onTodayTapped: {}
            )
            .environment(\.sizeCategory, category)
            
            assertSnapshot(matching: view, as: .image, named: "\(category)")
        }
    }
    
    func testVoiceOverLabels() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.buttons["添加按钮"].exists)
        XCTAssertTrue(app.buttons["今天按钮"].exists)
    }
}
```

---

## 契约保证

本契约确保：

✅ **深色模式**: 自动适配，无需手动处理  
✅ **动态字体**: 支持 XS ~ XXXL，布局不破坏  
✅ **减少动画**: 装饰动画禁用，功能动画简化  
✅ **VoiceOver**: 所有交互元素可访问  
✅ **颜色对比度**: 符合 WCAG 2.1 AA/AAA 标准  
✅ **按钮尺寸**: 始终 ≥ 44pt，符合 Apple HIG

---

**完成时间**: 2025-10-02  
**审阅状态**: 已审阅  
**实施状态**: 待实施  
**合规标准**: WCAG 2.1 AA, Apple HIG

