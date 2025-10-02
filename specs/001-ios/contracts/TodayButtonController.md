# Contract: TodayButtonController

**Purpose**: "今天"按钮显示控制接口，负责判断按钮是否应该显示

**Owner**: BottomNavigationBar  
**Consumers**: UI 层（按钮渲染逻辑）

---

## Interface Definition

```swift
protocol TodayButtonController {
    /// 当前选中的日期是否是今天
    var isTodaySelected: Bool { get }
    
    /// 是否应该显示"今天"按钮
    /// 规则：选中今天时隐藏，选中其他日期时显示
    var shouldShowTodayButton: Bool { get }
}
```

---

## Behavior Specification

### Property: `isTodaySelected`

#### Type
`Bool` - 当前选中的日期是否是今天

#### Computation
```swift
var isTodaySelected: Bool {
    Calendar.current.isDateInToday(selectedDate)
}
```

#### Guarantees
1. ✅ 基于 `selectedDate` 实时计算
2. ✅ 使用 `Calendar.isDateInToday()` 确保准确性
3. ✅ 自动处理日期变化（跨天）

#### Examples
```swift
// selectedDate = 2025-10-01 00:00:00
// Date() = 2025-10-01 15:30:00
controller.isTodaySelected  // true

// selectedDate = 2025-10-02 00:00:00
// Date() = 2025-10-01 15:30:00
controller.isTodaySelected  // false
```

---

### Property: `shouldShowTodayButton`

#### Type
`Bool` - 是否应该显示"今天"按钮

#### Business Logic
```swift
var shouldShowTodayButton: Bool {
    !isTodaySelected
}
```

#### Rules
| 选中日期 | isTodaySelected | shouldShowTodayButton | 说明 |
|---------|----------------|----------------------|------|
| 今天 | true | false ✅ | 已经在今天，隐藏按钮 |
| 昨天 | false | true ✅ | 不是今天，显示按钮 |
| 明天 | false | true ✅ | 不是今天，显示按钮 |
| 上周三 | false | true ✅ | 不是今天，显示按钮 |

#### Guarantees
1. ✅ 响应式更新：`selectedDate` 变化时自动重新计算
2. ✅ 一致性：选中今天后按钮立即隐藏
3. ✅ 可访问性：按钮显示/隐藏带有平滑过渡动画

#### Examples
```swift
// Scenario 1: 初始状态（今天）
// selectedDate = 今天
controller.shouldShowTodayButton  // false  ✅ 隐藏

// Scenario 2: 翻到下周
// selectedDate = 下周三
controller.shouldShowTodayButton  // true  ✅ 显示

// Scenario 3: 点击"今天"按钮
// selectedDate = 今天（跳转后）
controller.shouldShowTodayButton  // false  ✅ 隐藏
```

---

## Edge Cases

### Case 1: 跨天场景
**场景**: 用户在 23:59 选中今天，到了 00:00 自动变为昨天

**预期行为**:
- 23:59: `isTodaySelected = true`, `shouldShowTodayButton = false`
- 00:00: `isTodaySelected = false`, `shouldShowTodayButton = true`

**实现要求**:
- ⚠️ 需要在视图层添加定时器或 `onReceive` 监听日期变化
- 或者：用户下次操作时自动更新（推荐，更简单）

### Case 2: 时区变化
**场景**: 用户跨时区旅行

**预期行为**:
- 使用设备本地时区判断"今天"
- `Calendar.current.isDateInToday()` 自动处理时区

### Case 3: 快速点击
**场景**: 用户快速点击日期，UI 还未更新完成

**预期行为**:
- 因为是计算属性，总是基于最新的 `selectedDate`
- SwiftUI 自动确保一致性

---

## Contract Tests

### Test Suite: TodayButtonControllerTests

```swift
import XCTest

class TodayButtonControllerTests: XCTestCase {
    var controller: TodayButtonController!
    
    override func setUp() {
        super.setUp()
        // controller 通常是视图的一部分，这里模拟
    }
    
    // MARK: - isTodaySelected Tests
    
    func testIsTodaySelectedReturnsTrueWhenToday() {
        let controller = MockController(selectedDate: Date())
        XCTAssertTrue(controller.isTodaySelected)
    }
    
    func testIsTodaySelectedReturnsFalseWhenYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let controller = MockController(selectedDate: yesterday)
        XCTAssertFalse(controller.isTodaySelected)
    }
    
    func testIsTodaySelectedReturnsFalseWhenTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let controller = MockController(selectedDate: tomorrow)
        XCTAssertFalse(controller.isTodaySelected)
    }
    
    func testIsTodaySelectedHandlesSameDay() {
        let morning = createTime(hour: 8, minute: 0)
        let evening = createTime(hour: 20, minute: 30)
        
        let controller1 = MockController(selectedDate: morning)
        let controller2 = MockController(selectedDate: evening)
        
        // 同一天的不同时间都应该被认为是"今天"
        XCTAssertEqual(controller1.isTodaySelected, controller2.isTodaySelected)
    }
    
    // MARK: - shouldShowTodayButton Tests
    
    func testShouldShowTodayButtonHiddenWhenToday() {
        let controller = MockController(selectedDate: Date())
        XCTAssertFalse(controller.shouldShowTodayButton)
    }
    
    func testShouldShowTodayButtonVisibleWhenNotToday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let controller = MockController(selectedDate: yesterday)
        XCTAssertTrue(controller.shouldShowTodayButton)
    }
    
    func testShouldShowTodayButtonVisibleInPast() {
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let controller = MockController(selectedDate: lastWeek)
        XCTAssertTrue(controller.shouldShowTodayButton)
    }
    
    func testShouldShowTodayButtonVisibleInFuture() {
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        let controller = MockController(selectedDate: nextWeek)
        XCTAssertTrue(controller.shouldShowTodayButton)
    }
    
    // MARK: - Integration Tests
    
    func testButtonStateChangesWithDateSelection() {
        var controller = MockController(selectedDate: Date())
        XCTAssertFalse(controller.shouldShowTodayButton)  // 今天，隐藏
        
        // 选择明天
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        controller = MockController(selectedDate: tomorrow)
        XCTAssertTrue(controller.shouldShowTodayButton)  // 不是今天，显示
        
        // 回到今天
        controller = MockController(selectedDate: Date())
        XCTAssertFalse(controller.shouldShowTodayButton)  // 今天，隐藏
    }
    
    // MARK: - Helper
    
    private func createTime(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }
}

// MARK: - Mock Implementation

struct MockController: TodayButtonController {
    var selectedDate: Date
    
    var isTodaySelected: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    var shouldShowTodayButton: Bool {
        !isTodaySelected
    }
}
```

---

## Usage Example

### In BottomNavigationBar

```swift
struct BottomNavigationBar: View {
    @Binding var selectedDate: Date
    let onTodayTapped: () -> Void
    
    // MARK: - TodayButtonController Implementation
    
    private var isTodaySelected: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var shouldShowTodayButton: Bool {
        !isTodaySelected
    }
    
    var body: some View {
        HStack {
            // 今天按钮（条件显示）
            if shouldShowTodayButton {
                Button(action: onTodayTapped) {
                    Text("今天")
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "007AFF"))
                }
                .transition(.opacity)  // 平滑过渡
            }
            
            Spacer()
            
            // 添加按钮
            Button(action: { /* ... */ }) {
                Image(systemName: "plus.circle.fill")
            }
            
            Spacer()
            
            // 我的按钮
            Button(action: { /* ... */ }) {
                Text("我的")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: shouldShowTodayButton)
    }
}
```

---

## Accessibility Considerations

### VoiceOver 支持
```swift
if shouldShowTodayButton {
    Button(action: onTodayTapped) {
        Text("今天")
    }
    .accessibilityLabel("跳转到今天")
    .accessibilityHint("选择今天的日期并返回今天所在周")
}
```

### 动画无障碍
```swift
if shouldShowTodayButton {
    Button(action: onTodayTapped) {
        Text("今天")
    }
    .transition(.opacity)
    .animation(.easeInOut(duration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.2))
}
```

---

## Performance Considerations

### 计算复杂度
- **isTodaySelected**: O(1) - 简单日期比较
- **shouldShowTodayButton**: O(1) - 布尔取反

### 更新频率
- 只在 `selectedDate` 变化时重新计算
- SwiftUI 自动优化，无需手动缓存

### 内存占用
- 纯计算属性，无额外内存占用

---

## Implementation Checklist

- [ ] 在 `BottomNavigationBar` 中添加 `isTodaySelected` 计算属性
- [ ] 添加 `shouldShowTodayButton` 计算属性
- [ ] 使用 `if shouldShowTodayButton { }` 条件渲染按钮
- [ ] 添加 `.transition(.opacity)` 平滑过渡动画
- [ ] 测试选中今天时按钮隐藏
- [ ] 测试选中其他日期时按钮显示
- [ ] 测试点击"今天"按钮后按钮隐藏

---

**Status**: 契约已定义，等待实现  
**TDD Phase**: 🔴 RED (测试已写，实现未完成)  
**Complexity**: 低（简单的布尔逻辑）


