//
//  DateHelperBoundaryTests.swift
//  IdeaBoxTests
//
//  Created by AI Assistant on 2025-10-02.
//  边界情况测试：跨月、跨年、边界限制
//

import XCTest
@testable import IdeaBox

final class DateHelperBoundaryTests: XCTestCase {
    
    var dateHelper: DateHelper!
    
    override func setUp() {
        super.setUp()
        dateHelper = DateHelper.shared
    }
    
    override func tearDown() {
        dateHelper = nil
        super.tearDown()
    }
    
    // MARK: - 跨月测试
    
    /// 测试：3月31日到4月6日的跨月周
    /// 场景：一周横跨3月和4月边界
    func testCrossMonthWeek_March31ToApril6() {
        // Given: 2025年3月31日（周一）
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 31
        
        guard let march31 = calendar.date(from: components) else {
            XCTFail("无法创建测试日期")
            return
        }
        
        // When: 获取这一周的数据
        let weekOffset = dateHelper.weekOffset(for: march31, relativeTo: Date())
        let week = dateHelper.getWeek(offset: weekOffset, relativeTo: Date())
        
        // Then: 应该有7天
        XCTAssertEqual(week.days.count, 7, "跨月周应该有7天")
        
        // And: 验证日期连续性
        for i in 0..<6 {
            let currentDay = week.days[i]
            let nextDay = week.days[i + 1]
            let daysDiff = calendar.dateComponents([.day], from: currentDay.date, to: nextDay.date).day
            XCTAssertEqual(daysDiff, 1, "日期应该连续，第\(i)天到第\(i+1)天应该相差1天")
        }
        
        // And: 第一天应该是周一
        let firstDayWeekday = calendar.component(.weekday, from: week.days[0].date)
        XCTAssertEqual(firstDayWeekday, 2, "第一天应该是周一 (weekday=2)")
        
        // And: 最后一天应该是周日
        let lastDayWeekday = calendar.component(.weekday, from: week.days[6].date)
        XCTAssertEqual(lastDayWeekday, 1, "最后一天应该是周日 (weekday=1)")
    }
    
    /// 测试：2月28日/29日边界（含闰年）
    /// 场景：验证闰年2月的周数据正确性
    func testLeapYearFebruary() {
        // Given: 2024年2月29日（闰年）
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 2
        components.day = 29
        
        guard let feb29 = calendar.date(from: components) else {
            XCTFail("无法创建闰年2月29日")
            return
        }
        
        // When: 获取这一周的数据
        let weekOffset = dateHelper.weekOffset(for: feb29, relativeTo: Date())
        let week = dateHelper.getWeek(offset: weekOffset, relativeTo: Date())
        
        // Then: 应该包含2月29日
        let containsFeb29 = week.days.contains(where: { day in
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: day.date)
            return dayComponents.year == 2024 && dayComponents.month == 2 && dayComponents.day == 29
        })
        
        XCTAssertTrue(containsFeb29, "闰年周应该包含2月29日")
    }
    
    // MARK: - 跨年测试
    
    /// 测试：12月29日到1月4日的跨年周
    /// 场景：一周横跨年度边界
    func testCrossYearWeek_Dec29ToJan4() {
        // Given: 2024年12月30日（周一）
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 30
        
        guard let dec30 = calendar.date(from: components) else {
            XCTFail("无法创建测试日期")
            return
        }
        
        // When: 获取这一周的数据
        let weekOffset = dateHelper.weekOffset(for: dec30, relativeTo: Date())
        let week = dateHelper.getWeek(offset: weekOffset, relativeTo: Date())
        
        // Then: 应该有7天
        XCTAssertEqual(week.days.count, 7, "跨年周应该有7天")
        
        // And: 验证年份变化
        let firstDay = week.days[0]
        let lastDay = week.days[6]
        
        let firstYear = calendar.component(.year, from: firstDay.date)
        let lastYear = calendar.component(.year, from: lastDay.date)
        
        // 跨年周应该包含两个不同的年份
        XCTAssertNotEqual(firstYear, lastYear, "跨年周应该包含2024和2025年")
        
        // And: 日期应该连续
        for i in 0..<6 {
            let currentDay = week.days[i]
            let nextDay = week.days[i + 1]
            let daysDiff = calendar.dateComponents([.day], from: currentDay.date, to: nextDay.date).day
            XCTAssertEqual(daysDiff, 1, "跨年时日期应该连续")
        }
    }
    
    // MARK: - 边界限制测试
    
    /// 测试：向后边界（+52周）
    /// 场景：验证可以翻到未来52周
    func testBoundaryAt52WeeksForward() {
        // Given: 今天
        let today = Date()
        
        // When: 获取52周后的数据
        let week52 = dateHelper.getWeek(offset: 52, relativeTo: today)
        
        // Then: 应该成功返回
        XCTAssertEqual(week52.offset, 52, "偏移量应该是52")
        XCTAssertEqual(week52.days.count, 7, "应该有7天")
        
        // And: 验证日期是正确的未来日期
        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .weekOfYear, value: 52, to: today)!
        let weekOffset = dateHelper.weekOffset(for: expectedDate, relativeTo: today)
        
        // 允许±1周的误差（因为周的起始日是周一）
        XCTAssertTrue(abs(weekOffset - 52) <= 1, "52周后的日期应该在正确范围内")
    }
    
    /// 测试：向前边界（-52周）
    /// 场景：验证可以翻到过去52周
    func testBoundaryAt52WeeksBackward() {
        // Given: 今天
        let today = Date()
        
        // When: 获取52周前的数据
        let weekMinus52 = dateHelper.getWeek(offset: -52, relativeTo: today)
        
        // Then: 应该成功返回
        XCTAssertEqual(weekMinus52.offset, -52, "偏移量应该是-52")
        XCTAssertEqual(weekMinus52.days.count, 7, "应该有7天")
        
        // And: 验证日期是正确的过去日期
        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .weekOfYear, value: -52, to: today)!
        let weekOffset = dateHelper.weekOffset(for: expectedDate, relativeTo: today)
        
        // 允许±1周的误差
        XCTAssertTrue(abs(weekOffset + 52) <= 1, "52周前的日期应该在正确范围内")
    }
    
    /// 测试：边界外的行为（超出±52周）
    /// 场景：尝试获取超出边界的周数据，应该能正常返回（实际使用中由UI层控制边界）
    func testBeyondBoundary() {
        // Given: 今天
        let today = Date()
        
        // When: 尝试获取53周后的数据
        let week53 = dateHelper.getWeek(offset: 53, relativeTo: today)
        
        // Then: DateHelper 本身不限制，应该能返回
        XCTAssertEqual(week53.offset, 53, "DateHelper 应该能返回53周的数据")
        XCTAssertEqual(week53.days.count, 7, "应该有7天")
        
        // Note: 边界限制应该在 UI 层（WeekCalendarView 的 TabView）实现
    }
    
    // MARK: - 周偏移量对称性测试
    
    /// 测试：往返对称性
    /// 场景：从今天 +N周 再 -N周 应该回到今天所在周
    func testWeekOffsetSymmetry() {
        // Given: 今天
        let today = Date()
        let calendar = Calendar.current
        
        // When: 先向后10周
        let week10 = dateHelper.getWeek(offset: 10, relativeTo: today)
        
        // Then: 再向前10周，应该回到今天所在周
        let mondayOfWeek10 = week10.monday
        let backToToday = dateHelper.getWeek(offset: -10, relativeTo: mondayOfWeek10)
        
        // 验证包含今天
        let containsToday = backToToday.days.contains(where: { 
            calendar.isDate($0.date, inSameDayAs: today)
        })
        
        XCTAssertTrue(containsToday, "往返10周后应该回到今天所在周")
    }
}

