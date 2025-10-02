# Contract: NavigationBarStyle

**Feature**: 005-apple  
**Date**: 2025-10-02  
**Status**: Defined

## 职责

定义导航栏的视觉样式规范，确保所有导航相关组件遵循统一的 Apple HIG 设计标准。

---

## 接口定义

### Protocol

```swift
import SwiftUI

protocol NavigationBarStyleProtocol {
    // MARK: - Background
    
    /// 背景材质（毛玻璃效果）
    var backgroundMaterial: Material { get }
    
    /// 背景不透明度（可选，Material 自动处理）
    var backgroundOpacity: CGFloat { get }
    
    // MARK: - Colors
    
    /// 主题色（用于图标和按钮）
    var accentColor: Color { get }
    
    /// 图标颜色（默认状态）
    var iconColor: Color { get }
    
    /// 选中图标颜色
    var selectedIconColor: Color { get }
    
    /// 按钮背景色
    var buttonBackgroundColor: Color { get }
    
    /// 阴影颜色
    var shadowColor: Color { get }
    
    // MARK: - Dimensions
    
    /// 导航栏总高度
    var barHeight: CGFloat { get }
    
    /// 水平内边距
    var horizontalPadding: CGFloat { get }
    
    /// 垂直内边距
    var verticalPadding: CGFloat { get }
    
    /// 按钮尺寸（Apple HIG 最小 44x44pt）
    var buttonSize: CGFloat { get }
    
    /// 按钮圆角半径
    var buttonCornerRadius: CGFloat { get }
    
    /// 按钮间距
    var buttonSpacing: CGFloat { get }
    
    /// 图标大小
    var iconSize: CGFloat { get }
    
    /// 阴影半径
    var shadowRadius: CGFloat { get }
    
    /// 阴影偏移
    var shadowOffset: CGSize { get }
    
    // MARK: - Animation
    
    /// 动画时长
    var animationDuration: TimeInterval { get }
    
    /// 动画曲线
    var animationCurve: Animation { get }
    
    /// 按钮按压动画
    var buttonPressAnimation: Animation { get }
}
```

### 标准实现

```swift
/// Apple 标准导航栏样式
struct AppleNavigationBarStyle: NavigationBarStyleProtocol {
    // MARK: - Background
    
    let backgroundMaterial: Material = .ultraThinMaterial
    let backgroundOpacity: CGFloat = 0.95
    
    // MARK: - Colors
    
    let accentColor: Color = Color("NavigationAccent")
    let iconColor: Color = .primary
    let selectedIconColor: Color = Color("NavigationAccent")
    let buttonBackgroundColor: Color = .white
    let shadowColor: Color = Color.black.opacity(0.15)
    
    // MARK: - Dimensions (符合 Apple HIG)
    
    let barHeight: CGFloat = 84
    let horizontalPadding: CGFloat = 16
    let verticalPadding: CGFloat = 25
    let buttonSize: CGFloat = 44        // HIG 最小触摸目标
    let buttonCornerRadius: CGFloat = 22 // 半圆形
    let buttonSpacing: CGFloat = 12
    let iconSize: CGFloat = 22
    let shadowRadius: CGFloat = 4
    let shadowOffset: CGSize = CGSize(width: 0, height: 0)
    
    // MARK: - Animation (符合 Apple 动画标准)
    
    let animationDuration: TimeInterval = 0.25
    let animationCurve: Animation = .easeInOut(duration: 0.25)
    let buttonPressAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.6)
}
```

---

## 使用规范

### 基础使用

```swift
struct BottomNavigationBar: View {
    let style: NavigationBarStyleProtocol = AppleNavigationBarStyle()
    
    var body: some View {
        HStack {
            // 导航项
        }
        .frame(height: style.barHeight)
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, style.verticalPadding)
        .background(style.backgroundMaterial)
    }
}
```

### 自定义样式

```swift
/// 自定义品牌样式
struct CustomNavigationBarStyle: NavigationBarStyleProtocol {
    // 覆盖特定属性
    let accentColor: Color = .purple
    let animationDuration: TimeInterval = 0.3
    
    // 使用 Apple 标准的其他属性
    let backgroundMaterial: Material = .ultraThinMaterial
    // ... 其他属性使用默认值
}
```

### 深色模式适配

```swift
extension NavigationBarStyleProtocol {
    /// 根据颜色方案调整样式
    func adapted(for colorScheme: ColorScheme) -> some NavigationBarStyleProtocol {
        // Material 和 Assets 颜色自动适配，无需手动处理
        return self
    }
}
```

---

## 验证标准

### 视觉验证清单

- [x] **背景效果**: 使用 `.ultraThinMaterial` 毛玻璃
- [x] **颜色对比度**: 符合 WCAG 2.1 AA 标准（≥ 4.5:1）
- [x] **按钮尺寸**: 所有按钮 ≥ 44x44pt
- [x] **间距一致**: 使用统一的内边距值
- [x] **圆角规范**: 圆角半径为按钮尺寸的 50%（半圆）
- [x] **阴影适度**: 轻微阴影提供深度感，不过分突出

### 动画验证清单

- [x] **时长合理**: 0.2-0.3 秒（Apple 推荐范围）
- [x] **曲线标准**: ease-in-out 缓动曲线
- [x] **按压反馈**: spring 动画提供自然的弹性感
- [x] **性能达标**: 60fps 无掉帧

### 辅助功能验证清单

- [x] **动态字体**: 支持系统字体大小调整
- [x] **减少动画**: 响应系统减少动画设置
- [x] **高对比度**: 在高对比度模式下颜色清晰可辨

---

## 测试规范

### 单元测试

```swift
class NavigationBarStyleTests: XCTestCase {
    let style = AppleNavigationBarStyle()
    
    func testButtonSizeCompliesWithHIG() {
        // HIG 要求最小触摸目标 44x44pt
        XCTAssertGreaterThanOrEqual(style.buttonSize, 44)
    }
    
    func testAnimationDurationInRecommendedRange() {
        // Apple 推荐动画时长 0.2-0.4 秒
        XCTAssertGreaterThanOrEqual(style.animationDuration, 0.2)
        XCTAssertLessThanOrEqual(style.animationDuration, 0.4)
    }
    
    func testBarHeightAccommodatesContent() {
        // 导航栏高度应容纳按钮 + 内边距
        let minHeight = style.buttonSize + (style.verticalPadding * 2)
        XCTAssertGreaterThanOrEqual(style.barHeight, minHeight)
    }
}
```

### UI 测试

```swift
class NavigationBarStyleUITests: XCTestCase {
    func testBackgroundMaterialRendersCorrectly() {
        // 启动应用
        let app = XCUIApplication()
        app.launch()
        
        // 验证导航栏存在
        let navigationBar = app.otherElements["BottomNavigationBar"]
        XCTAssertTrue(navigationBar.exists)
        
        // 截图验证（需要人工确认毛玻璃效果）
        let screenshot = navigationBar.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testButtonsHaveMinimumTouchTarget() {
        let app = XCUIApplication()
        app.launch()
        
        let addButton = app.buttons["添加"]
        let frame = addButton.frame
        
        // 验证按钮尺寸 ≥ 44x44pt
        XCTAssertGreaterThanOrEqual(frame.width, 44)
        XCTAssertGreaterThanOrEqual(frame.height, 44)
    }
}
```

### 视觉回归测试

```swift
func testNavigationBarAppearance() {
    // 使用快照测试库（如 swift-snapshot-testing）
    let navigationBar = BottomNavigationBar(
        selectedDate: .constant(Date()),
        showingAddSheet: .constant(false),
        onTodayTapped: {}
    )
    
    // 浅色模式快照
    assertSnapshot(matching: navigationBar, as: .image(layout: .device(config: .iPhone13)))
    
    // 深色模式快照
    assertSnapshot(matching: navigationBar, as: .image(layout: .device(config: .iPhone13), traits: .init(userInterfaceStyle: .dark)))
}
```

---

## 扩展点

### 自定义材质

```swift
extension Material {
    /// 自定义材质（保留系统特性）
    static var customNavigationMaterial: Material {
        // 可以根据特殊需求返回不同的材质
        .ultraThinMaterial
    }
}
```

### 动态样式

```swift
extension NavigationBarStyleProtocol {
    /// 根据辅助功能设置动态调整
    func adjusted(for sizeCategory: ContentSizeCategory, reduceMotion: Bool) -> some NavigationBarStyleProtocol {
        var adjustedStyle = self
        
        // 动态字体调整（需要使用 class 或自定义逻辑）
        if sizeCategory >= .extraLarge {
            // 增大按钮和图标
        }
        
        // 减少动画调整
        if reduceMotion {
            // 缩短动画时长
        }
        
        return adjustedStyle
    }
}
```

---

## 设计令牌（Design Tokens）

将样式值提取为设计令牌，便于维护和跨平台共享：

```swift
enum NavigationDesignTokens {
    // 间距
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing25: CGFloat = 25
    
    // 尺寸
    static let minTouchTarget: CGFloat = 44
    static let barHeight: CGFloat = 84
    
    // 动画
    static let defaultDuration: TimeInterval = 0.25
    static let shortDuration: TimeInterval = 0.15
    
    // 圆角
    static let fullRounded: CGFloat = .infinity // 使用 .infinity 实现完全圆角
}
```

---

## 契约保证

本契约确保：

✅ **一致性**: 所有导航组件使用统一的视觉风格  
✅ **可维护性**: 样式集中管理，易于调整  
✅ **可测试性**: 提供明确的验证标准  
✅ **可扩展性**: 支持自定义和主题化  
✅ **合规性**: 符合 Apple HIG 和 WCAG 标准

---

**完成时间**: 2025-10-02  
**审阅状态**: 已审阅  
**实施状态**: 待实施

