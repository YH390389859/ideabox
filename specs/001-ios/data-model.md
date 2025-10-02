# Phase 1: Data Model Design
**Feature**: iOS 风格周视图日历  
**Date**: 2025-10-01

## Overview

本文档定义实现 iOS 风格周视图日历所需的数据模型和状态结构。

---

## Core Models

### 1. WeekData (新增)

**用途**: 表示完整的一周数据（周一到周日）

```swift
struct WeekData: Identifiable, Equatable {
    /// 唯一标识符
    let id: UUID
    
    /// 周偏移量（相对于今天所在周）
    /// 0 = 今天所在周, -1 = 上一周, +1 = 下一周
    let offset: Int
    
    /// 周一的日期
    let monday: Date
    
    /// 周日的日期
    let sunday: Date
    
    /// 7天的数据（周一到周日）
    let days: [DayItem]
    
    /// 是否包含今天
    var containsToday: Bool {
        days.contains { $0.isToday }
    }
    
    /// 获取指定星期几的日期
    /// - Parameter weekday: 1-7 (1=周一, 7=周日)
    func date(for weekday: Int) -> Date? {
        guard weekday >= 1 && weekday <= 7 else { return nil }
        return days[weekday - 1].date
    }
    
    /// Equatable 实现
    static func == (lhs: WeekData, rhs: WeekData) -> Bool {
        Calendar.current.isDate(lhs.monday, inSameDayAs: rhs.monday)
    }
}
```

**属性说明**:
| 属性 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | ✅ | SwiftUI 列表标识 |
| offset | Int | ✅ | 周偏移量，用于 TabView selection |
| monday | Date | ✅ | 周起始日期 |
| sunday | Date | ✅ | 周结束日期 |
| days | [DayItem] | ✅ | 7个 DayItem，索引 0-6 对应周一到周日 |

**计算属性**:
- `containsToday`: 判断本周是否包含今天
- `date(for:)`: 根据星期几获取具体日期

**验证规则**:
- ✅ days.count 必须等于 7
- ✅ days[0].date 必须是周一
- ✅ days[6].date 必须是周日
- ✅ days 中日期必须连续

---

### 2. DayItem (已存在，需增强)

**现有定义**:
```swift
struct DayItem: Identifiable, Equatable {
    let id: UUID
    let weekday: String      // "一", "二", ..., "日"
    let day: Int             // 日期数字
    let date: Date           // 完整日期
    let isToday: Bool        // 是否是今天
}
```

**建议增强**:
```swift
struct DayItem: Identifiable, Equatable {
    let id: UUID
    let weekday: String
    let day: Int
    let date: Date
    let isToday: Bool
    
    // 新增：周内索引（1-7，1=周一）
    let weekdayIndex: Int
    
    // 新增：是否被选中
    var isSelected: Bool
    
    /// Equatable 实现
    static func == (lhs: DayItem, rhs: DayItem) -> Bool {
        Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)
    }
}
```

**新增属性**:
| 属性 | 类型 | 必填 | 说明 |
|------|------|------|------|
| weekdayIndex | Int | ✅ | 1-7，用于快速定位和翻周保持 |
| isSelected | Bool | ⚠️ | 可选，可通过外部比较 selectedDate 判断 |

**建议**: `isSelected` 可以不加到模型中，在视图层通过计算属性判断：
```swift
let isSelected = Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
```

**最终决策**: 仅新增 `weekdayIndex`，保持模型简洁。

---

### 3. DateSelection State (视图状态，非独立模型)

**用途**: 管理日期选择和周导航状态

```swift
// 在 ContentView 中管理
@State private var selectedDate: Date = Date()

// 在 WeekCalendarView 中管理
@State private var currentWeekOffset: Int = 0

// 计算属性
private var selectedWeekday: Int {
    let weekday = Calendar.current.component(.weekday, from: selectedDate)
    return (weekday + 5) % 7 + 1  // 转换为 1-7 (1=周一)
}
```

**状态流**:
```
用户操作 → 更新 currentWeekOffset → 生成新 WeekData 
                                      ↓
                              更新 selectedDate (保持星期几)
                                      ↓
                              触发 UI 重绘
```

---

## Data Flow Architecture

### 状态层级

```
ContentView
├── @State selectedDate: Date
│   └── 传递给所有子视图
│
├── WeekCalendarView
│   ├── @State currentWeekOffset: Int
│   ├── @Binding selectedDate: Date
│   └── 计算: WeekData (基于 offset)
│
└── BottomNavigationBar
    ├── @Binding selectedDate: Date
    └── 计算: shouldShowTodayButton
```

### 数据流向

#### 1. 翻周操作
```
用户左滑
  ↓
currentWeekOffset += 1
  ↓
生成新的 WeekData (offset = currentWeekOffset)
  ↓
计算新的 selectedDate (保持原星期几，新的周)
  ↓
WeekCalendarView 和 BottomNavigationBar 自动更新
```

#### 2. 点击日期
```
用户点击周内某一天
  ↓
selectedDate = 点击的日期
  ↓
currentWeekOffset 不变（不翻周）
  ↓
日期高亮更新，"今天"按钮显示状态更新
```

#### 3. 点击"今天"按钮
```
用户点击"今天"
  ↓
currentWeekOffset = 0 (回到今天所在周)
  ↓
selectedDate = Date() (今天)
  ↓
视图跳转，按钮隐藏
```

---

## Helper Methods (DateHelper 扩展)

### 新增方法

```swift
extension DateHelper {
    /// 获取指定日期所在周的周一
    func getMonday(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: date)!
    }
    
    /// 生成周数据
    /// - Parameters:
    ///   - offset: 周偏移量（相对于 baseDate 所在周）
    ///   - baseDate: 基准日期（默认为今天）
    /// - Returns: WeekData 对象
    func getWeek(offset: Int, relativeTo baseDate: Date = Date()) -> WeekData {
        let baseMonday = getMonday(for: baseDate)
        let targetMonday = calendar.date(byAdding: .weekOfYear, 
                                          value: offset, 
                                          to: baseMonday)!
        
        let days = (0..<7).map { dayOffset -> DayItem in
            let date = calendar.date(byAdding: .day, 
                                      value: dayOffset, 
                                      to: targetMonday)!
            let day = calendar.component(.day, from: date)
            let weekday = getWeekdayString(from: date)
            let isToday = self.isToday(date)
            let weekdayIndex = dayOffset + 1
            
            return DayItem(
                weekday: weekday,
                day: day,
                date: date,
                isToday: isToday,
                weekdayIndex: weekdayIndex
            )
        }
        
        let sunday = calendar.date(byAdding: .day, value: 6, to: targetMonday)!
        
        return WeekData(
            id: UUID(),
            offset: offset,
            monday: targetMonday,
            sunday: sunday,
            days: days
        )
    }
    
    /// 计算两个日期之间的周偏移量
    /// - Parameters:
    ///   - date: 目标日期
    ///   - baseDate: 基准日期
    /// - Returns: 周偏移量
    func weekOffset(for date: Date, relativeTo baseDate: Date) -> Int {
        let monday1 = getMonday(for: baseDate)
        let monday2 = getMonday(for: date)
        let components = calendar.dateComponents([.weekOfYear], 
                                                   from: monday1, 
                                                   to: monday2)
        return components.weekOfYear ?? 0
    }
    
    /// 根据星期几在指定周获取日期
    /// - Parameters:
    ///   - weekData: 周数据
    ///   - weekday: 星期几 (1-7, 1=周一)
    /// - Returns: 对应日期
    func dateInWeek(_ weekData: WeekData, weekday: Int) -> Date? {
        weekData.date(for: weekday)
    }
}
```

---

## State Validation Rules

### WeekData 创建验证
```swift
func validateWeekData(_ week: WeekData) -> Bool {
    // 1. 必须有7天
    guard week.days.count == 7 else { return false }
    
    // 2. 第一天必须是周一
    let firstDayWeekday = Calendar.current.component(.weekday, from: week.days[0].date)
    guard firstDayWeekday == 2 else { return false }  // 2 = 周一
    
    // 3. 最后一天必须是周日
    let lastDayWeekday = Calendar.current.component(.weekday, from: week.days[6].date)
    guard lastDayWeekday == 1 else { return false }  // 1 = 周日
    
    // 4. 日期必须连续
    for i in 0..<6 {
        let diff = Calendar.current.dateComponents([.day], 
                                                     from: week.days[i].date, 
                                                     to: week.days[i+1].date)
        guard diff.day == 1 else { return false }
    }
    
    return true
}
```

### Boundary Validation
```swift
func isWeekOffsetValid(_ offset: Int) -> Bool {
    return offset >= -52 && offset <= 52
}
```

---

## Performance Considerations

### 内存优化
- **TabView 自动管理**: 仅保持当前周 + 前后各1周在内存
- **WeekData 轻量**: 每个 WeekData 约 700 字节
- **最大内存**: 3周 × 700字节 ≈ 2.1KB（可忽略）

### 计算优化
- **缓存基准周一**: 避免重复计算今天所在周的周一
  ```swift
  private let todayMonday = dateHelper.getMonday(for: Date())
  ```
- **惰性计算**: 仅在 TabView 滚动到该页时才生成 WeekData
- **复用 Calendar**: 使用单例，避免频繁创建

---

## Testing Strategy

### 单元测试

#### WeekData 模型测试
```swift
class WeekDataTests: XCTestCase {
    func testWeekDataContainsSevenDays() {
        let week = dateHelper.getWeek(offset: 0)
        XCTAssertEqual(week.days.count, 7)
    }
    
    func testWeekStartsOnMonday() {
        let week = dateHelper.getWeek(offset: 0)
        let weekday = Calendar.current.component(.weekday, from: week.monday)
        XCTAssertEqual(weekday, 2)  // 2 = 周一
    }
    
    func testWeekEndsOnSunday() {
        let week = dateHelper.getWeek(offset: 0)
        let weekday = Calendar.current.component(.weekday, from: week.sunday)
        XCTAssertEqual(weekday, 1)  // 1 = 周日
    }
    
    func testContainsToday() {
        let week = dateHelper.getWeek(offset: 0)
        XCTAssertTrue(week.containsToday)
        
        let lastWeek = dateHelper.getWeek(offset: -1)
        XCTAssertFalse(lastWeek.containsToday)
    }
}
```

#### DateHelper 周计算测试
```swift
class DateHelperWeekTests: XCTestCase {
    func testGetMonday() {
        // 2025-10-01 是周三
        let wednesday = createDate(2025, 10, 1)
        let monday = dateHelper.getMonday(for: wednesday)
        // 应该返回 2025-09-29 (周一)
        XCTAssertEqual(monday, createDate(2025, 9, 29))
    }
    
    func testWeekOffsetCalculation() {
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)!
        let offset = dateHelper.weekOffset(for: nextWeek, relativeTo: today)
        XCTAssertEqual(offset, 1)
    }
    
    func testCrossMonthWeek() {
        // 2025-03-31 (周一) 到 2025-04-06 (周日)
        let week = dateHelper.getWeek(offset: /* 计算偏移 */)
        XCTAssertEqual(week.monday, createDate(2025, 3, 31))
        XCTAssertEqual(week.sunday, createDate(2025, 4, 6))
    }
    
    func testCrossYearWeek() {
        // 2025-12-29 (周一) 到 2026-01-04 (周日)
        let week = dateHelper.getWeek(offset: /* 计算偏移 */)
        XCTAssertEqual(week.monday, createDate(2025, 12, 29))
        XCTAssertEqual(week.sunday, createDate(2026, 1, 4))
    }
}
```

---

## Migration Notes

### 从现有实现迁移

#### 1. DayItem 增强
```swift
// 旧版本
DayItem(weekday: "三", day: 1, date: date, isToday: true)

// 新版本 (添加 weekdayIndex)
DayItem(weekday: "三", day: 1, date: date, isToday: true, weekdayIndex: 3)
```

#### 2. WeekCalendarView 数据源变化
```swift
// 旧版本：扩展的 days 数组
let days: [DayItem] = dateHelper.getExtendedDays(...)

// 新版本：基于偏移量的周数据
TabView(selection: $weekOffset) {
    ForEach(-52...52, id: \.self) { offset in
        let week = dateHelper.getWeek(offset: offset)
        // 使用 week.days
    }
}
```

---

## Summary

### 新增数据结构
1. ✅ **WeekData**: 完整周数据模型
2. ✅ **DayItem.weekdayIndex**: 新增属性

### 新增 Helper 方法
1. ✅ `getMonday(for:)`: 获取周一日期
2. ✅ `getWeek(offset:relativeTo:)`: 生成周数据
3. ✅ `weekOffset(for:relativeTo:)`: 计算周偏移量
4. ✅ `dateInWeek(_:weekday:)`: 获取周内特定日期

### 状态管理
- ✅ `currentWeekOffset`: 当前周偏移量 (@State)
- ✅ `selectedDate`: 选中日期 (@State / @Binding)
- ✅ 计算属性：`selectedWeekday`, `shouldShowTodayButton`

---

**Next**: 定义接口契约 (contracts/) 和快速开始指南 (quickstart.md)


