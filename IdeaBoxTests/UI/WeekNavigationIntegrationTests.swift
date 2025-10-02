//
//  WeekNavigationIntegrationTests.swift
//  IdeaBoxTests
//
//  Created by AI Assistant on 2025-10-02.
//  集成测试：验证完整的翻周用户流程
//

import XCTest
@testable import IdeaBox

final class WeekNavigationIntegrationTests: XCTestCase {
    
    var dateHelper: DateHelper!
    
    override func setUp() {
        super.setUp()
        dateHelper = DateHelper.shared
    }
    
    override func tearDown() {
        dateHelper = nil
        super.tearDown()
    }
    
    // MARK: - 翻周并保持星期几测试
    
    /// 测试：向后翻周并保持星期几
    /// 场景：用户在周三，向左滑动翻到下一周，应该自动选中下周三
    func testNavigateToNextWeekAndPreserveWeekday() {
        // Given: 当前选中周三
        let calendar = Calendar.current
        let today = Date()
        let wednesday = getSpecificWeekday(3, relativeTo: today) // 3 = 周三
        
        // When: 获取下一周
        let nextWeek = dateHelper.getWeek(offset: 1, relativeTo: today)
        
        // Then: 下一周的周三应该存在
        let nextWednesday = nextWeek.days.first(where: { 
            calendar.component(.weekday, from: $0.date) == 4 // 4 = 周三 (Sunday = 1)
        })
        
        XCTAssertNotNil(nextWednesday, "下一周应该有周三")
        
        // 验证日期间隔是7天
        let daysDiff = calendar.dateComponents([.day], from: wednesday, to: nextWednesday!.date).day
        XCTAssertEqual(daysDiff, 7, "下周三应该正好是7天后")
    }
    
    /// 测试：向前翻周并保持星期几
    /// 场景：用户在周五，向右滑动翻到上一周，应该自动选中上周五
    func testNavigateToPreviousWeekAndPreserveWeekday() {
        // Given: 当前选中周五
        let calendar = Calendar.current
        let today = Date()
        let friday = getSpecificWeekday(5, relativeTo: today) // 5 = 周五
        
        // When: 获取上一周
        let previousWeek = dateHelper.getWeek(offset: -1, relativeTo: today)
        
        // Then: 上一周的周五应该存在
        let previousFriday = previousWeek.days.first(where: { 
            calendar.component(.weekday, from: $0.date) == 6 // 6 = 周五 (Sunday = 1)
        })
        
        XCTAssertNotNil(previousFriday, "上一周应该有周五")
        
        // 验证日期间隔是-7天
        let daysDiff = calendar.dateComponents([.day], from: previousFriday!.date, to: friday).day
        XCTAssertEqual(daysDiff, 7, "上周五应该正好是7天前")
    }
    
    /// 测试：连续多次翻周
    /// 场景：用户连续翻3周，每次都应该保持星期几不变
    func testMultipleWeekNavigation() {
        // Given: 从今天开始，记录星期几
        let calendar = Calendar.current
        let today = Date()
        let initialWeekday = calendar.component(.weekday, from: today)
        
        // When: 连续向后翻3周
        for offset in 1...3 {
            let week = dateHelper.getWeek(offset: offset, relativeTo: today)
            
            // Then: 每一周都应该有相同星期几的日期
            let matchingDay = week.days.first(where: { 
                calendar.component(.weekday, from: $0.date) == initialWeekday
            })
            
            XCTAssertNotNil(matchingDay, "第\(offset)周应该有星期\(initialWeekday)")
            
            // 验证日期间隔
            let daysDiff = calendar.dateComponents([.day], from: today, to: matchingDay!.date).day
            XCTAssertEqual(daysDiff, offset * 7, "第\(offset)周应该是\(offset * 7)天后")
        }
    }
    
    /// 测试：翻周到边界
    /// 场景：翻到最大/最小偏移量，确保不会崩溃
    func testNavigationToBoundary() {
        // When: 翻到最大边界 (+52周)
        let maxWeek = dateHelper.getWeek(offset: 52, relativeTo: Date())
        
        // Then: 应该成功返回52周后的数据
        XCTAssertEqual(maxWeek.days.count, 7, "边界周应该有7天")
        XCTAssertEqual(maxWeek.offset, 52, "偏移量应该是52")
        
        // When: 翻到最小边界 (-52周)
        let minWeek = dateHelper.getWeek(offset: -52, relativeTo: Date())
        
        // Then: 应该成功返回52周前的数据
        XCTAssertEqual(minWeek.days.count, 7, "边界周应该有7天")
        XCTAssertEqual(minWeek.offset, -52, "偏移量应该是-52")
    }
    
    // MARK: - Helper Methods
    
    /// 获取相对于某日期的特定星期几
    /// - Parameters:
    ///   - weekday: 星期几 (1=周一, 7=周日)
    ///   - date: 基准日期
    /// - Returns: 特定星期几的日期
    private func getSpecificWeekday(_ weekday: Int, relativeTo date: Date) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        
        // Convert to Monday-based (1=Monday, 7=Sunday)
        let mondayBasedCurrent = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        let daysToAdd = weekday - mondayBasedCurrent
        return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
    }
}

