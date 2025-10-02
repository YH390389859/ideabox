# Data Model: Apple 风格底部导航栏

**Feature**: 005-apple  
**Date**: 2025-10-02  
**Status**: Complete

## 模型概述

本文档定义了底部导航栏所需的数据模型和状态管理结构。遵循 SwiftUI 单向数据流原则，确保状态可预测和可测试。

---

## 1. NavigationItem (导航项)

### 定义

```swift
import SwiftUI

/// 导航栏中的单个导航项
struct NavigationItem: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let selectedIcon: String
    let action: () -> Void
    var isVisible: Bool = true
    var badge: Int? = nil
    
    // Equatable conformance (忽略 action 闭包)
    static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.icon == rhs.icon &&
        lhs.selectedIcon == rhs.selectedIcon &&
        lhs.isVisible == rhs.isVisible &&
        lhs.badge == rhs.badge
    }
}
```

### 字段说明

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `id` | String | ✓ | 唯一标识符，用于状态管理和列表渲染 |
| `title` | String | ✓ | 导航项显示文本，主要用于 VoiceOver |
| `icon` | String | ✓ | 默认状态的 SF Symbol 名称 |
| `selectedIcon` | String | ✓ | 选中状态的 SF Symbol 名称（通常是 .fill 版本） |
| `action` | () -> Void | ✓ | 点击回调闭包 |
| `isVisible` | Bool | - | 可见性标志（默认 true），用于条件显示 |
| `badge` | Int? | - | 徽章数量（预留字段，当前版本不使用） |

### 验证规则

```swift
extension NavigationItem {
    /// 验证导航项配置是否有效
    func validate() -> [String] {
        var errors: [String] = []
        
        // 验证 ID 不为空
        if id.isEmpty {
            errors.append("Navigation item ID cannot be empty")
        }
        
        // 验证标题不为空
        if title.isEmpty {
            errors.append("Navigation item title cannot be empty (required for VoiceOver)")
        }
        
        // 验证图标名称格式（基础检查）
        if icon.isEmpty {
            errors.append("Navigation item icon cannot be empty")
        }
        if selectedIcon.isEmpty {
            errors.append("Navigation item selectedIcon cannot be empty")
        }
        
        // 验证徽章数量范围
        if let badge = badge, badge < 0 {
            errors.append("Badge count cannot be negative")
        }
        
        return errors
    }
}
```

### 使用示例

```swift
// 创建"今天"按钮导航项
let todayItem = NavigationItem(
    id: "today",
    title: "今天",
    icon: "calendar.badge.clock",
    selectedIcon: "calendar.badge.clock.fill",
    action: {
        // 跳转到今天的逻辑
    },
    isVisible: !Calendar.current.isDateInToday(selectedDate)
)

// 创建"添加"按钮导航项
let addItem = NavigationItem(
    id: "add",
    title: "添加",
    icon: "plus.circle.fill",
    selectedIcon: "plus.circle.fill",
    action: {
        showingAddSheet = true
    }
)

// 创建"个人中心"导航项
let profileItem = NavigationItem(
    id: "profile",
    title: "个人中心",
    icon: "person.crop.circle",
    selectedIcon: "person.crop.circle.fill",
    action: {
        // 导航到个人页面
    }
)
```

---

## 2. NavigationState (导航状态)

### 定义

```swift
import Foundation

/// 导航栏的状态管理
struct NavigationState: Equatable {
    /// 当前选中的导航项 ID
    var selectedItemId: String?
    
    /// 是否正在执行动画
    var isAnimating: Bool = false
    
    /// 上一次选中的导航项 ID（用于转场动画）
    var previousItemId: String?
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `selectedItemId` | String? | 当前选中的导航项 ID，nil 表示无选中 |
| `isAnimating` | Bool | 动画状态标志，防止动画冲突 |
| `previousItemId` | String? | 前一个选中的 ID，用于共享元素转场 |

### 状态转换

```
[Idle] ──select(itemId)──> [Selected]
[Selected] ──deselect()──> [Idle]
[Selected] ──select(newId)──> [Animating] ──complete──> [Selected]
```

### 状态管理器

```swift
import Combine

/// 导航状态管理器（可选：用于复杂场景）
@MainActor
class NavigationStateManager: ObservableObject {
    @Published var state: NavigationState = NavigationState()
    
    /// 选中导航项
    func select(itemId: String) {
        guard state.selectedItemId != itemId else { return }
        
        state.previousItemId = state.selectedItemId
        state.isAnimating = true
        state.selectedItemId = itemId
        
        // 动画完成后重置标志
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 秒
            state.isAnimating = false
        }
    }
    
    /// 取消选中
    func deselect() {
        state.previousItemId = state.selectedItemId
        state.selectedItemId = nil
    }
    
    /// 检查是否选中
    func isSelected(_ itemId: String) -> Bool {
        state.selectedItemId == itemId
    }
}
```

### 使用示例

```swift
struct ContentView: View {
    @StateObject private var navigationManager = NavigationStateManager()
    
    var body: some View {
        VStack {
            // 主内容区域
            
            BottomNavigationBar(
                selectedItemId: $navigationManager.state.selectedItemId,
                items: navigationItems
            )
        }
    }
}
```

---

## 3. NavigationBarConfiguration (导航栏配置)

### 定义

```swift
import SwiftUI

/// 导航栏外观和行为配置
struct NavigationBarConfiguration {
    // MARK: - 视觉样式
    
    /// 背景材质
    var backgroundMaterial: Material = .ultraThinMaterial
    
    /// 主题色（用于图标和按钮）
    var accentColor: Color = Color("NavigationAccent")
    
    /// 导航栏高度
    var barHeight: CGFloat = 84
    
    /// 水平内边距
    var horizontalPadding: CGFloat = 16
    
    /// 垂直内边距
    var verticalPadding: CGFloat = 25
    
    // MARK: - 按钮样式
    
    /// 按钮尺寸（HIG 最小触摸目标）
    var buttonSize: CGFloat = 44
    
    /// 按钮圆角半径
    var buttonCornerRadius: CGFloat = 22
    
    /// 按钮间距
    var buttonSpacing: CGFloat = 12
    
    /// 图标大小
    var iconSize: CGFloat = 22
    
    // MARK: - 动画参数
    
    /// 动画时长
    var animationDuration: TimeInterval = 0.25
    
    /// 动画曲线
    var animationCurve: Animation = .easeInOut(duration: 0.25)
    
    /// 按钮按压动画
    var buttonPressAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.6)
    
    // MARK: - 触觉反馈
    
    /// 启用触觉反馈
    var hapticsEnabled: Bool = true
    
    /// 标准按钮触觉强度
    var buttonHapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
    
    /// 主要操作触觉强度
    var primaryActionHapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
}
```

### 预设配置

```swift
extension NavigationBarConfiguration {
    /// Apple 标准配置（默认）
    static let apple = NavigationBarConfiguration()
    
    /// 紧凑配置（较小设备）
    static let compact = NavigationBarConfiguration(
        barHeight: 72,
        horizontalPadding: 12,
        buttonSize: 40,
        iconSize: 20
    )
    
    /// 大号配置（辅助功能）
    static let large = NavigationBarConfiguration(
        barHeight: 96,
        buttonSize: 52,
        iconSize: 26
    )
}
```

### 动态配置（响应辅助功能）

```swift
extension NavigationBarConfiguration {
    /// 根据内容大小类别调整配置
    static func adaptive(for sizeCategory: ContentSizeCategory) -> NavigationBarConfiguration {
        switch sizeCategory {
        case .extraSmall, .small, .medium:
            return .compact
        case .extraLarge, .extraExtraLarge, .extraExtraExtraLarge:
            return .large
        default:
            return .apple
        }
    }
    
    /// 根据减少动画设置调整
    func withReducedMotion(_ enabled: Bool) -> NavigationBarConfiguration {
        var config = self
        if enabled {
            config.animationDuration = 0.15
            config.animationCurve = .linear
        }
        return config
    }
}
```

---

## 4. 数据流图

```
┌─────────────────────────────────────────────────┐
│            ContentView (Root)                   │
│  @State selectedDate: Date                      │
│  @State showingAddSheet: Bool                   │
└──────────────┬──────────────────────────────────┘
               │
               │ @Binding
               ▼
┌─────────────────────────────────────────────────┐
│       BottomNavigationBar (View)                │
│  @Binding selectedDate                          │
│  @Binding showingAddSheet                       │
│  @State private config: NavigationBarConfiguration │
└──────────────┬──────────────────────────────────┘
               │
               │ creates
               ▼
┌─────────────────────────────────────────────────┐
│       NavigationItem (Model)                    │
│  - id, title, icon                              │
│  - action: () -> Void                           │
│  - isVisible: Bool                              │
└─────────────────────────────────────────────────┘
```

### 状态传递规则

1. **单向数据流**: 数据从父组件流向子组件
2. **@Binding 通信**: 子组件通过 @Binding 通知父组件状态变化
3. **局部状态**: 纯 UI 状态（如动画）使用 @State 管理
4. **全局状态**: 跨页面状态使用 @EnvironmentObject 或单例

---

## 5. 测试数据

### Mock Data

```swift
#if DEBUG
extension NavigationItem {
    /// 测试用的今天按钮
    static var mockToday: NavigationItem {
        NavigationItem(
            id: "today",
            title: "今天",
            icon: "calendar.badge.clock",
            selectedIcon: "calendar.badge.clock.fill",
            action: { print("Today tapped") }
        )
    }
    
    /// 测试用的添加按钮
    static var mockAdd: NavigationItem {
        NavigationItem(
            id: "add",
            title: "添加",
            icon: "plus.circle.fill",
            selectedIcon: "plus.circle.fill",
            action: { print("Add tapped") }
        )
    }
    
    /// 测试用的个人按钮
    static var mockProfile: NavigationItem {
        NavigationItem(
            id: "profile",
            title: "个人中心",
            icon: "person.crop.circle",
            selectedIcon: "person.crop.circle.fill",
            action: { print("Profile tapped") }
        )
    }
    
    /// 完整的导航项集合
    static var mockItems: [NavigationItem] {
        [mockToday, mockAdd, mockProfile]
    }
}
#endif
```

---

## 6. 数据验证

### 单元测试清单

```swift
// NavigationItemTests.swift
class NavigationItemTests: XCTestCase {
    func testNavigationItemCreation() {
        let item = NavigationItem.mockToday
        XCTAssertEqual(item.id, "today")
        XCTAssertEqual(item.title, "今天")
        XCTAssertTrue(item.isVisible)
    }
    
    func testNavigationItemValidation() {
        let validItem = NavigationItem.mockToday
        XCTAssertTrue(validItem.validate().isEmpty)
        
        let invalidItem = NavigationItem(
            id: "",
            title: "",
            icon: "",
            selectedIcon: "",
            action: {}
        )
        XCTAssertFalse(invalidItem.validate().isEmpty)
    }
    
    func testNavigationItemEquality() {
        let item1 = NavigationItem.mockToday
        let item2 = NavigationItem.mockToday
        XCTAssertEqual(item1, item2)
    }
}

// NavigationStateTests.swift
class NavigationStateTests: XCTestCase {
    func testStateTransitions() {
        var state = NavigationState()
        XCTAssertNil(state.selectedItemId)
        
        state.selectedItemId = "today"
        XCTAssertEqual(state.selectedItemId, "today")
    }
    
    func testNavigationStateManager() async {
        let manager = NavigationStateManager()
        XCTAssertNil(manager.state.selectedItemId)
        
        manager.select(itemId: "today")
        XCTAssertEqual(manager.state.selectedItemId, "today")
        XCTAssertTrue(manager.state.isAnimating)
        
        // 等待动画完成
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertFalse(manager.state.isAnimating)
    }
}
```

---

## 总结

### 数据模型清单

| 模型 | 职责 | 状态管理 |
|------|------|---------|
| NavigationItem | 导航项定义 | 不可变（结构体） |
| NavigationState | 导航状态 | 可变（@State/@Published） |
| NavigationBarConfiguration | 外观配置 | 不可变（带预设） |

### 设计原则

✅ **不可变性**: 模型结构体尽量不可变
✅ **可测试性**: 提供 Mock 数据和验证方法
✅ **类型安全**: 使用强类型，避免字符串魔法值
✅ **文档完整**: 所有公开接口有注释

### 下一步

✓ 数据模型定义完成
→ 创建 contracts/ 契约文档
→ 定义组件接口和行为规范

---

**完成时间**: 2025-10-02  
**审阅状态**: 通过  
**准备进入**: Contracts 定义阶段

