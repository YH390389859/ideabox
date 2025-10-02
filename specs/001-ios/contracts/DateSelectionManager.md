# Contract: DateSelectionManager

**Purpose**: 日期选择管理接口，负责处理日期选择、周导航和"今天"跳转逻辑

**Owner**: ContentView (状态管理层)  
**Consumers**: WeekCalendarView, BottomNavigationBar

---

## Interface Definition

```swift
protocol DateSelectionManager {
    /// 当前选中的日期
    var selectedDate: Date { get set }
    
    /// 当前显示的周偏移量（相对于今天所在周）
    var currentWeekOffset: Int { get }
    
    /// 选中某个日期（不改变周偏移量）
    /// - Parameter date: 要选中的日期
    /// - Precondition: date 必须在当前显示的周内
    func selectDate(_ date: Date)
    
    /// 导航到指定偏移量的周
    /// - Parameters:
    ///   - offset: 周偏移量
    ///   - preserveWeekday: 是否保持星期几不变
    func navigateToWeek(offset: Int, preserveWeekday: Bool)
    
    /// 跳转到今天
    /// - Postcondition: selectedDate = 今天, currentWeekOffset = 0
    func jumpToToday()
}
```

---

## Behavior Specification

### Property: `selectedDate`

#### Type
`Date` - 当前选中的日期

#### Guarantees
1. ✅ 初始值为今天
2. ✅ 任何时候都不为 nil
3. ✅ 修改后触发 UI 更新

#### Observable
是，通过 `@Published` 或 `@State` 实现响应式更新

---

### Property: `currentWeekOffset`

#### Type
`Int` - 当前显示的周相对于今天所在周的偏移量

#### Guarantees
1. ✅ 初始值为 0（今天所在周）
2. ✅ 范围限制在 [-52, 52]
3. ✅ 修改后触发周数据重新生成

#### Computed
可以是计算属性，基于 `selectedDate` 计算

---

### Method: `selectDate(_:)`

#### Purpose
用户点击周内某一天时调用

#### Inputs
- `date: Date` - 要选中的日期

#### Side Effects
1. ✅ 更新 `selectedDate`
2. ✅ 不修改 `currentWeekOffset`（不翻周）
3. ✅ 触发 UI 重绘（高亮变化、"今天"按钮显示状态变化）

#### Preconditions
- date 应该在当前显示的周内（不强制，但推荐）

#### Examples
```swift
// 当前显示 10月7日-10月13日这一周
// selectedDate = 10月10日（周三）

manager.selectDate(createDate(2025, 10, 11))  // 选择周四
// Result: selectedDate = 10月11日
//         currentWeekOffset 不变
//         周视图不翻页
```

---

### Method: `navigateToWeek(offset:preserveWeekday:)`

#### Purpose
用户左右滑动翻周时调用

#### Inputs
- `offset: Int` - 目标周偏移量
- `preserveWeekday: Bool` - 是否保持星期几不变

#### Side Effects
1. ✅ 更新 `currentWeekOffset` 为 offset
2. ✅ 如果 `preserveWeekday == true`，计算新周的同星期几日期并更新 `selectedDate`
3. ✅ 如果 `preserveWeekday == false`，可以保持 `selectedDate` 不变或设为新周的第一天

#### Guarantees
1. ✅ offset 会被限制在 [-52, 52] 范围内
2. ✅ 翻周动画流畅（由视图层控制）

#### Examples
```swift
// 当前: selectedDate = 10月10日（周三）, currentWeekOffset = 0

// Example 1: 向后翻周，保持星期几
manager.navigateToWeek(offset: 1, preserveWeekday: true)
// Result: currentWeekOffset = 1
//         selectedDate = 10月17日（下周三）  ✅ 保持周三

// Example 2: 向前翻周，保持星期几
manager.navigateToWeek(offset: -1, preserveWeekday: true)
// Result: currentWeekOffset = -1
//         selectedDate = 10月3日（上周三）  ✅ 保持周三

// Example 3: 边界处理
manager.navigateToWeek(offset: 100, preserveWeekday: true)
// Result: currentWeekOffset = 52  ✅ 限制在边界
```

---

### Method: `jumpToToday()`

#### Purpose
用户点击"今天"按钮时调用

#### Side Effects
1. ✅ 设置 `selectedDate = Date()`（今天）
2. ✅ 设置 `currentWeekOffset = 0`（今天所在周）
3. ✅ 触发视图跳转到今天所在周

#### Guarantees
1. ✅ 执行后，`selectedDate` 总是今天
2. ✅ 执行后，"今天"按钮应该隐藏

#### Examples
```swift
// 当前: selectedDate = 10月3日, currentWeekOffset = -1 (上周)

manager.jumpToToday()
// Result: selectedDate = 10月10日 (今天)
//         currentWeekOffset = 0
//         "今天"按钮隐藏
```

---

## State Machine

### 状态转换图

```
┌──────────────────┐
│  初始状态         │
│  selectedDate =  │
│  今天            │
│  offset = 0      │
└────────┬─────────┘
         │
         ├─ selectDate(_) ──→ 仅更新 selectedDate
         │                    offset 不变
         │
         ├─ navigateToWeek() ──→ 更新 offset
         │                        更新 selectedDate (保持星期几)
         │
         └─ jumpToToday() ──→ 回到初始状态
```

### 不变量 (Invariants)

1. **边界限制**: `currentWeekOffset` 总是在 [-52, 52] 范围内
2. **日期一致性**: 如果 `selectedDate` 是今天，则 `currentWeekOffset` 应该是 0
3. **星期几保持**: 翻周时，如果 `preserveWeekday == true`，新旧 `selectedDate` 的星期几相同

---

## Contract Tests

### Test Suite: DateSelectionManagerTests

```swift
import XCTest

class DateSelectionManagerTests: XCTestCase {
    var manager: DateSelectionManager!
    
    override func setUp() {
        super.setUp()
        manager = createManager()  // 工厂方法创建实现
    }
    
    // MARK: - Initialization Tests
    
    func testInitialSelectedDateIsToday() {
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInToday(manager.selectedDate))
    }
    
    func testInitialWeekOffsetIsZero() {
        XCTAssertEqual(manager.currentWeekOffset, 0)
    }
    
    // MARK: - selectDate Tests
    
    func testSelectDateUpdatesSelectedDate() {
        let targetDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        manager.selectDate(targetDate)
        
        XCTAssertTrue(Calendar.current.isDate(manager.selectedDate, inSameDayAs: targetDate))
    }
    
    func testSelectDateDoesNotChangeWeekOffset() {
        let initialOffset = manager.currentWeekOffset
        let targetDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        
        manager.selectDate(targetDate)
        
        XCTAssertEqual(manager.currentWeekOffset, initialOffset)
    }
    
    // MARK: - navigateToWeek Tests
    
    func testNavigateToNextWeekUpdatesOffset() {
        manager.navigateToWeek(offset: 1, preserveWeekday: false)
        XCTAssertEqual(manager.currentWeekOffset, 1)
    }
    
    func testNavigateToNextWeekPreservesWeekday() {
        let initialWeekday = Calendar.current.component(.weekday, from: manager.selectedDate)
        
        manager.navigateToWeek(offset: 1, preserveWeekday: true)
        
        let newWeekday = Calendar.current.component(.weekday, from: manager.selectedDate)
        XCTAssertEqual(newWeekday, initialWeekday)
    }
    
    func testNavigateToLastWeekPreservesWeekday() {
        // 先选中周三
        let wednesday = findWeekday(3, in: Date())  // 3 = 周三
        manager.selectDate(wednesday)
        
        manager.navigateToWeek(offset: -1, preserveWeekday: true)
        
        let newWeekday = Calendar.current.component(.weekday, from: manager.selectedDate)
        XCTAssertEqual(newWeekday, 4)  // 4 = 周三 (weekday从周日=1开始)
    }
    
    func testNavigateToBoundaryClamps() {
        manager.navigateToWeek(offset: 100, preserveWeekday: false)
        XCTAssertEqual(manager.currentWeekOffset, 52)  // 限制在最大值
        
        manager.navigateToWeek(offset: -100, preserveWeekday: false)
        XCTAssertEqual(manager.currentWeekOffset, -52)  // 限制在最小值
    }
    
    // MARK: - jumpToToday Tests
    
    func testJumpToTodayResetsToToday() {
        // 先导航到其他周
        manager.navigateToWeek(offset: 5, preserveWeekday: true)
        
        manager.jumpToToday()
        
        XCTAssertTrue(Calendar.current.isDateInToday(manager.selectedDate))
        XCTAssertEqual(manager.currentWeekOffset, 0)
    }
    
    func testJumpToTodayFromPastWeek() {
        manager.navigateToWeek(offset: -10, preserveWeekday: true)
        
        manager.jumpToToday()
        
        XCTAssertTrue(Calendar.current.isDateInToday(manager.selectedDate))
    }
    
    // MARK: - Invariant Tests
    
    func testOffsetAlwaysInBounds() {
        for offset in [-100, -52, 0, 52, 100] {
            manager.navigateToWeek(offset: offset, preserveWeekday: false)
            XCTAssertTrue(manager.currentWeekOffset >= -52 && manager.currentWeekOffset <= 52)
        }
    }
    
    // MARK: - Helper
    
    private func findWeekday(_ targetWeekday: Int, in date: Date) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        let diff = targetWeekday - currentWeekday
        return calendar.date(byAdding: .day, value: diff, to: date)!
    }
}
```

---

## Usage Example

### In ContentView

```swift
struct ContentView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentWeekOffset: Int = 0
    
    var body: some View {
        VStack {
            WeekCalendarView(
                weekOffset: $currentWeekOffset,
                selectedDate: $selectedDate,
                onSelectDate: { date in
                    selectDate(date)
                },
                onNavigateToWeek: { offset in
                    navigateToWeek(offset: offset, preserveWeekday: true)
                }
            )
            
            BottomNavigationBar(
                selectedDate: selectedDate,
                onTodayTapped: {
                    jumpToToday()
                }
            )
        }
    }
    
    // MARK: - DateSelectionManager Implementation
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        // currentWeekOffset 不变
    }
    
    private func navigateToWeek(offset: Int, preserveWeekday: Bool) {
        let clampedOffset = max(-52, min(52, offset))
        currentWeekOffset = clampedOffset
        
        if preserveWeekday {
            let weekday = Calendar.current.component(.weekday, from: selectedDate)
            let newWeek = DateHelper.shared.getWeek(offset: clampedOffset)
            selectedDate = newWeek.days.first { 
                Calendar.current.component(.weekday, from: $0.date) == weekday 
            }?.date ?? newWeek.days[0].date
        }
    }
    
    private func jumpToToday() {
        selectedDate = Date()
        currentWeekOffset = 0
    }
}
```

---

## Implementation Checklist

- [ ] 定义 `selectedDate` 和 `currentWeekOffset` 状态
- [ ] 实现 `selectDate(_)` 方法
- [ ] 实现 `navigateToWeek(offset:preserveWeekday:)` 方法
- [ ] 实现 `jumpToToday()` 方法
- [ ] 添加边界限制逻辑（-52 到 52）
- [ ] 所有测试用例通过
- [ ] 验证星期几保持逻辑正确性

---

**Status**: 契约已定义，等待实现  
**TDD Phase**: 🔴 RED (测试已写，实现未完成)


