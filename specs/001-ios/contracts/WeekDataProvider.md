# Contract: WeekDataProvider

**Purpose**: 周数据提供接口，负责生成和计算周相关的日期数据

**Owner**: DateHelper  
**Consumers**: WeekCalendarView, ContentView

---

## Interface Definition

```swift
protocol WeekDataProvider {
    /// 获取指定偏移量的周数据
    /// - Parameters:
    ///   - offset: 周偏移量（0=今天所在周, -1=上周, +1=下周）
    ///   - baseDate: 基准日期（默认为今天）
    /// - Returns: WeekData 对象，包含完整7天数据
    /// - Precondition: offset 必须在 [-52, 52] 范围内
    func getWeek(offset: Int, relativeTo baseDate: Date) -> WeekData
    
    /// 计算目标日期相对于基准日期的周偏移量
    /// - Parameters:
    ///   - date: 目标日期
    ///   - baseDate: 基准日期
    /// - Returns: 周偏移量（整数）
    func weekOffset(for date: Date, relativeTo baseDate: Date) -> Int
    
    /// 获取指定周内某星期几的日期
    /// - Parameters:
    ///   - weekData: 周数据
    ///   - weekday: 星期几 (1-7, 1=周一, 7=周日)
    /// - Returns: 对应日期，如果 weekday 无效则返回 nil
    func dateInWeek(_ weekData: WeekData, weekday: Int) -> Date?
}
```

---

## Behavior Specification

### Method: `getWeek(offset:relativeTo:)`

#### Inputs
- `offset: Int` - 周偏移量
  - **Valid Range**: [-52, 52]
  - **0**: 今天所在周
  - **正数**: 未来的周
  - **负数**: 过去的周
- `baseDate: Date` - 基准日期（通常为今天）

#### Outputs
- `WeekData` 对象，包含：
  - 7个 DayItem（周一到周日）
  - 周一和周日的日期
  - 偏移量值
  - 是否包含今天的标志

#### Guarantees
1. ✅ 返回的 WeekData.days 总是包含7个元素
2. ✅ days[0] 总是周一，days[6] 总是周日
3. ✅ 所有日期连续，无间隔
4. ✅ 正确处理跨月、跨年情况

#### Examples
```swift
// Example 1: 获取今天所在周
let thisWeek = provider.getWeek(offset: 0, relativeTo: Date())
// Result: 包含今天的周一到周日

// Example 2: 获取下一周
let nextWeek = provider.getWeek(offset: 1, relativeTo: Date())
// Result: 下周的周一到周日

// Example 3: 跨年情况 (2025-12-31 是周三)
let baseDate = createDate(2025, 12, 31)
let week = provider.getWeek(offset: 0, relativeTo: baseDate)
// week.monday = 2025-12-29
// week.sunday = 2026-01-04  ✅ 正确跨年
```

---

### Method: `weekOffset(for:relativeTo:)`

#### Inputs
- `date: Date` - 目标日期
- `baseDate: Date` - 基准日期

#### Outputs
- `Int` - 周偏移量
  - 0: 同一周
  - 正数: date 在 baseDate 之后
  - 负数: date 在 baseDate 之前

#### Guarantees
1. ✅ `weekOffset(for: baseDate, relativeTo: baseDate)` 总是返回 0
2. ✅ 对称性: `weekOffset(A, B) == -weekOffset(B, A)`
3. ✅ 传递性: 周偏移量可累加

#### Examples
```swift
let today = Date()
let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)!

let offset = provider.weekOffset(for: nextWeek, relativeTo: today)
// Result: 1

let reverseOffset = provider.weekOffset(for: today, relativeTo: nextWeek)
// Result: -1  ✅ 对称
```

---

### Method: `dateInWeek(_:weekday:)`

#### Inputs
- `weekData: WeekData` - 周数据
- `weekday: Int` - 星期几 (1-7)
  - 1 = 周一
  - 2 = 周二
  - ...
  - 7 = 周日

#### Outputs
- `Date?` - 对应日期，无效输入返回 nil

#### Guarantees
1. ✅ weekday 在 [1, 7] 范围内总是返回有效日期
2. ✅ weekday 超出范围返回 nil
3. ✅ 返回的日期总是在 weekData 的范围内

#### Examples
```swift
let week = provider.getWeek(offset: 0, relativeTo: Date())

let monday = provider.dateInWeek(week, weekday: 1)
// Result: 本周周一

let invalid = provider.dateInWeek(week, weekday: 8)
// Result: nil  ✅ 超出范围
```

---

## Contract Tests

### Test Suite: WeekDataProviderTests

```swift
import XCTest

class WeekDataProviderTests: XCTestCase {
    var provider: WeekDataProvider!
    
    override func setUp() {
        super.setUp()
        provider = DateHelper.shared  // 实际实现
    }
    
    // MARK: - getWeek Tests
    
    func testGetWeekReturnsSevenDays() {
        let week = provider.getWeek(offset: 0, relativeTo: Date())
        XCTAssertEqual(week.days.count, 7)
    }
    
    func testGetWeekStartsOnMonday() {
        let week = provider.getWeek(offset: 0, relativeTo: Date())
        let weekday = Calendar.current.component(.weekday, from: week.days[0].date)
        XCTAssertEqual(weekday, 2)  // 2 = 周一
    }
    
    func testGetWeekEndsOnSunday() {
        let week = provider.getWeek(offset: 0, relativeTo: Date())
        let weekday = Calendar.current.component(.weekday, from: week.days[6].date)
        XCTAssertEqual(weekday, 1)  // 1 = 周日
    }
    
    func testGetWeekDaysAreContinuous() {
        let week = provider.getWeek(offset: 0, relativeTo: Date())
        for i in 0..<6 {
            let diff = Calendar.current.dateComponents([.day], 
                                                         from: week.days[i].date,
                                                         to: week.days[i+1].date)
            XCTAssertEqual(diff.day, 1, "Day \(i) and \(i+1) should be continuous")
        }
    }
    
    func testGetWeekHandlesCrossMonth() {
        // 2025-03-31 是周一
        let baseDate = createDate(2025, 3, 31)
        let week = provider.getWeek(offset: 0, relativeTo: baseDate)
        
        XCTAssertEqual(week.monday, createDate(2025, 3, 31))
        XCTAssertEqual(week.sunday, createDate(2025, 4, 6))  // 跨到4月
    }
    
    func testGetWeekHandlesCrossYear() {
        // 2025-12-31 是周三，本周一是 2025-12-29
        let baseDate = createDate(2025, 12, 31)
        let week = provider.getWeek(offset: 0, relativeTo: baseDate)
        
        XCTAssertEqual(week.monday, createDate(2025, 12, 29))
        XCTAssertEqual(week.sunday, createDate(2026, 1, 4))  // 跨到2026年
    }
    
    func testGetWeekNegativeOffset() {
        let today = Date()
        let thisWeek = provider.getWeek(offset: 0, relativeTo: today)
        let lastWeek = provider.getWeek(offset: -1, relativeTo: today)
        
        let diff = Calendar.current.dateComponents([.weekOfYear],
                                                     from: lastWeek.monday,
                                                     to: thisWeek.monday)
        XCTAssertEqual(diff.weekOfYear, 1)
    }
    
    func testGetWeekPositiveOffset() {
        let today = Date()
        let thisWeek = provider.getWeek(offset: 0, relativeTo: today)
        let nextWeek = provider.getWeek(offset: 1, relativeTo: today)
        
        let diff = Calendar.current.dateComponents([.weekOfYear],
                                                     from: thisWeek.monday,
                                                     to: nextWeek.monday)
        XCTAssertEqual(diff.weekOfYear, 1)
    }
    
    // MARK: - weekOffset Tests
    
    func testWeekOffsetSameWeekReturnsZero() {
        let date = Date()
        let offset = provider.weekOffset(for: date, relativeTo: date)
        XCTAssertEqual(offset, 0)
    }
    
    func testWeekOffsetNextWeekReturnsOne() {
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)!
        let offset = provider.weekOffset(for: nextWeek, relativeTo: today)
        XCTAssertEqual(offset, 1)
    }
    
    func testWeekOffsetLastWeekReturnsMinusOne() {
        let today = Date()
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)!
        let offset = provider.weekOffset(for: lastWeek, relativeTo: today)
        XCTAssertEqual(offset, -1)
    }
    
    func testWeekOffsetSymmetry() {
        let date1 = Date()
        let date2 = Calendar.current.date(byAdding: .weekOfYear, value: 3, to: date1)!
        
        let offset1 = provider.weekOffset(for: date2, relativeTo: date1)
        let offset2 = provider.weekOffset(for: date1, relativeTo: date2)
        
        XCTAssertEqual(offset1, -offset2)
    }
    
    // MARK: - dateInWeek Tests
    
    func testDateInWeekReturnsMonday() {
        let week = provider.getWeek(offset: 0, relativeTo: Date())
        let monday = provider.dateInWeek(week, weekday: 1)
        
        XCTAssertNotNil(monday)
        XCTAssertEqual(monday, week.days[0].date)
    }
    
    func testDateInWeekReturnsSunday() {
        let week = provider.getWeek(offset: 0, relativeTo: Date())
        let sunday = provider.dateInWeek(week, weekday: 7)
        
        XCTAssertNotNil(sunday)
        XCTAssertEqual(sunday, week.days[6].date)
    }
    
    func testDateInWeekInvalidWeekdayReturnsNil() {
        let week = provider.getWeek(offset: 0, relativeTo: Date())
        
        XCTAssertNil(provider.dateInWeek(week, weekday: 0))
        XCTAssertNil(provider.dateInWeek(week, weekday: 8))
        XCTAssertNil(provider.dateInWeek(week, weekday: -1))
    }
    
    // MARK: - Helper
    
    private func createDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components)!
    }
}
```

---

## Implementation Checklist

- [ ] 实现 `getWeek(offset:relativeTo:)` 方法
- [ ] 实现 `weekOffset(for:relativeTo:)` 方法
- [ ] 实现 `dateInWeek(_:weekday:)` 方法
- [ ] 所有测试用例通过（红 → 绿）
- [ ] 处理边界条件（前后52周限制）
- [ ] 性能验证（生成周数据 < 10ms）
- [ ] 代码审查通过

---

**Status**: 契约已定义，等待实现  
**TDD Phase**: 🔴 RED (测试已写，实现未完成)


