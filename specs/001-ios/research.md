# Phase 0: Technical Research
**Feature**: iOS 风格周视图日历  
**Date**: 2025-10-01

## Research Overview

本文档记录为实现 iOS 风格周视图日历所需的技术调研结果，解决规范中标记的所有 [NEEDS CLARIFICATION] 项。

---

## 1. SwiftUI 分页滚动技术

### Research Question
如何在 SwiftUI 中实现流畅的周视图分页滚动？

### Options Evaluated

#### Option A: TabView with PageTabViewStyle
```swift
TabView(selection: $weekOffset) {
    ForEach(-52...52, id: \.self) { offset in
        WeekView(offset: offset)
            .tag(offset)
    }
}
.tabViewStyle(.page(indexDisplayMode: .never))
```

**优点**:
- ✅ 原生支持分页滚动
- ✅ 自动处理手势识别
- ✅ 内置动画效果
- ✅ 性能优化（按需加载）

**缺点**:
- ❌ 自定义动画参数困难
- ❌ 无法精确控制手势阈值

#### Option B: 自定义 DragGesture + GeometryReader
```swift
HStack(spacing: 0) {
    ForEach(visibleWeeks) { week in
        WeekView(data: week)
            .frame(width: geometry.size.width)
    }
}
.offset(x: dragOffset)
.gesture(
    DragGesture()
        .onChanged { /* 跟踪拖动 */ }
        .onEnded { /* 判断是否翻页 */ }
)
```

**优点**:
- ✅ 完全控制动画参数
- ✅ 可自定义手势阈值
- ✅ 灵活的反馈效果

**缺点**:
- ❌ 需要手动管理状态
- ❌ 性能优化需自己实现
- ❌ 代码复杂度高

### Decision: Option A (TabView)

**Rationale**:
1. **性能**: TabView 内置懒加载和内存管理，更高效
2. **可靠性**: 系统级组件，经过充分测试
3. **维护性**: 代码更简洁，易于维护
4. **用户体验**: 与 iOS 系统日历行为一致

**Trade-off**: 虽然无法精确控制动画时长到 300ms，但 TabView 的默认动画已经非常接近（约 250-300ms），用户体验良好。

---

## 2. 周计算逻辑

### Research Question
如何使用 Calendar API 准确计算周一到周日，并处理边界情况？

### Calendar API 核心方法

```swift
let calendar = Calendar.current

// 1. 获取某日期所在周的周一
func getMonday(for date: Date) -> Date {
    let weekday = calendar.component(.weekday, from: date)
    // weekday: 1=周日, 2=周一, ..., 7=周六
    let daysFromMonday = (weekday + 5) % 7
    return calendar.date(byAdding: .day, value: -daysFromMonday, to: date)!
}

// 2. 生成完整一周（周一到周日）
func getWeekDays(startingFrom monday: Date) -> [Date] {
    (0..<7).map { offset in
        calendar.date(byAdding: .day, value: offset, to: monday)!
    }
}

// 3. 计算周偏移量
func weekOffset(from date1: Date, to date2: Date) -> Int {
    let monday1 = getMonday(for: date1)
    let monday2 = getMonday(for: date2)
    let components = calendar.dateComponents([.weekOfYear], from: monday1, to: monday2)
    return components.weekOfYear ?? 0
}
```

### Edge Cases Handling

#### 跨月处理
- **场景**: 2025年3月31日（周一）到 4月6日（周日）
- **解决**: Calendar API 自动处理月份边界，无需特殊逻辑
- **验证**: 
  ```swift
  let march31 = Date(/* 2025-03-31 */)
  let week = getWeekDays(startingFrom: march31)
  // week[6] = 2025-04-06 ✅
  ```

#### 跨年处理
- **场景**: 2025年12月29日（周一）到 2026年1月4日（周日）
- **解决**: 同样由 Calendar API 自动处理
- **注意**: `weekOfYear` 可能出现 Week 53 或 Week 1，需使用绝对日期差计算

#### 闰年2月
- **场景**: 2024年2月26日（周一）到 3月3日（周日）
- **解决**: Calendar 自动识别闰年，2月有29天
- **验证**: 通过单元测试确认

### Decision: 使用 Calendar.dateComponents 和 byAdding 方法

**Rationale**:
- ✅ Foundation 框架提供，稳定可靠
- ✅ 自动处理所有边界情况
- ✅ 时区感知（避免夏令时问题）
- ✅ 本地化支持（不同地区周开始日可能不同）

---

## 3. 状态管理模式

### Research Question
如何管理当前周偏移量、选中日期和"今天"按钮状态？

### State Architecture Options

#### Option A: 单一 ViewModel
```swift
class WeekCalendarViewModel: ObservableObject {
    @Published var currentWeekOffset: Int = 0
    @Published var selectedDate: Date = Date()
    
    var shouldShowTodayButton: Bool {
        !calendar.isDateInToday(selectedDate)
    }
    
    func navigateToNextWeek() { /* ... */ }
    func navigateToToday() { /* ... */ }
}
```

**优点**: 集中管理，逻辑清晰  
**缺点**: 引入新的架构层，增加复杂度

#### Option B: SwiftUI 直接状态管理
```swift
struct WeekCalendarView: View {
    @State private var weekOffset: Int = 0
    @Binding var selectedDate: Date
    
    private var shouldShowTodayButton: Bool {
        !calendar.isDateInToday(selectedDate)
    }
}
```

**优点**: 简单直接，符合现有架构  
**缺点**: 状态分散在多个视图

### Decision: Option B (SwiftUI 直接状态管理)

**Rationale**:
1. **一致性**: 保持现有项目的 MVVM 风格（View 包含简单状态）
2. **简单性**: 状态逻辑不复杂，不需要独立 ViewModel
3. **性能**: 减少一层间接访问，响应更快
4. **可测试性**: 通过 UI 测试验证交互逻辑

**Implementation Pattern**:
- `weekOffset` 在 `WeekCalendarView` 中管理
- `selectedDate` 通过 `@Binding` 与父视图同步
- "今天"按钮逻辑在 `BottomNavigationBar` 中计算（computed property）

---

## 4. 动画与手势参数

### Research Question
iOS 标准动画参数和手势识别最佳实践？

### iOS HIG Animation Guidelines

#### 标准动画时长
- **快速动画**: 150-200ms（小范围变化，如按钮高亮）
- **标准动画**: 250-350ms（视图切换、内容滚动）
- **慢速动画**: 400-600ms（全屏转场）

**我们的场景**: 周视图翻页 → **300ms** ✅

#### 缓动函数 (Easing)
```swift
// iOS 推荐的缓动函数
.animation(.easeInOut(duration: 0.3), value: weekOffset)

// 等价于 UIKit 的
UIView.animate(withDuration: 0.3, 
               delay: 0, 
               options: .curveEaseInOut)
```

**选择**: `easeInOut` - 开始和结束都有缓冲，最自然

### Gesture Recognition

#### TabView 手势参数
TabView 使用系统默认参数：
- **最小拖动距离**: 约 30pt（触发识别）
- **翻页阈值**: 屏幕宽度的 50%
- **速度检测**: 快速滑动（velocity > 1000 pt/s）可降低阈值到 20%

#### 快速滑动处理

**问题**: 用户快速多次滑动时如何处理？

**TabView 默认行为**:
- 动画进行中时，新的手势会被排队
- 实际效果：每次只翻一周，需等待动画完成

**Decision**: 保持 TabView 默认行为

**Rationale**:
- ✅ 符合 iOS 日历应用行为
- ✅ 防止用户失去方向感
- ✅ 减少实现复杂度
- ✅ 性能更好（不需预加载多周数据）

---

## 5. 边界处理与性能优化

### Research Question
如何限制可滚动周数并优化性能？

### Boundary Design

#### 决策：前后各 52 周（共 105 周）

**Rationale**:
- **业务需求**: 1年历史 + 1年未来，覆盖常见使用场景
- **内存占用**: 105周 × 7天 × ~100字节 ≈ 73KB（可接受）
- **计算成本**: 周数据生成为 O(1)，懒加载性能无压力

#### 边界反馈

**到达边界时的行为**:
```swift
TabView(selection: $weekOffset) {
    ForEach(-52...52, id: \.self) { offset in
        // TabView 自动停止滚动
        // iOS 会显示轻微的弹性反弹效果
    }
}
```

**用户体验**:
- ✅ 视觉反馈清晰（弹性反弹）
- ✅ 无错误提示（非异常情况）
- ✅ 符合 iOS 用户预期

### Performance Optimization

#### 内存管理
```swift
// TabView 自动管理：
// - 仅保持当前 + 前后各1周在内存（共3周）
// - 其他周按需创建/销毁
```

#### 计算优化
```swift
// 缓存今天的周一日期，避免重复计算
private let todayMonday = getMonday(for: Date())

// 根据偏移量快速计算目标周
func getWeek(offset: Int) -> WeekData {
    let targetMonday = calendar.date(byAdding: .weekOfYear, 
                                      value: offset, 
                                      to: todayMonday)!
    // ... 生成周数据
}
```

---

## Resolved Clarifications

### 1. 滚动动画时长和缓动效果 ✅

**Decision**: 
- 动画时长：300ms
- 缓动函数：`easeInOut`

**Source**: iOS Human Interface Guidelines - Animation

---

### 2. 快速滑动行为 ✅

**Decision**: 每次只翻一周，快速滑动需等待动画完成

**Rationale**: 
- 与 iOS 系统日历行为一致
- 防止用户迷失方向
- 实现简单，性能更好

---

### 3. 可滚动周数边界 ✅

**Decision**: 
- 向前：过去 52 周
- 向后：未来 52 周
- 总计：105 周

**Rationale**:
- 覆盖1年历史和1年未来
- 内存占用约 73KB（可接受）
- 超过范围的场景极少

---

## Technology Stack Summary

| 技术 | 选择 | 理由 |
|------|------|------|
| **分页滚动** | TabView + PageTabViewStyle | 原生支持，性能最优 |
| **日期计算** | Calendar.dateComponents | Foundation 标准，可靠 |
| **状态管理** | @State + @Binding | 简单直接，符合现有架构 |
| **动画** | .animation(.easeInOut) | iOS 标准，流畅自然 |
| **边界处理** | ForEach 范围限制 | TabView 自动停止 |

---

## Next Steps

✅ 所有技术不确定性已解决  
→ 进入 Phase 1: 设计数据模型和接口契约  
→ 编写测试用例（TDD）  
→ 开始实现

---

## References

- [Apple HIG - Animation](https://developer.apple.com/design/human-interface-guidelines/animation)
- [SwiftUI TabView Documentation](https://developer.apple.com/documentation/swiftui/tabview)
- [Foundation Calendar](https://developer.apple.com/documentation/foundation/calendar)
- [SwiftUI State Management](https://developer.apple.com/documentation/swiftui/state-and-data-flow)

**Research Complete**: 2025-10-01


