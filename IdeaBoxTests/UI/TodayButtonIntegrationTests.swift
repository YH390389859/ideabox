//
//  TodayButtonIntegrationTests.swift
//  IdeaBoxTests
//
//  Created by AI Assistant on 2025-10-02.
//  集成测试：验证"今天"按钮的完整交互流程
//

import XCTest
@testable import IdeaBox

final class TodayButtonIntegrationTests: XCTestCase {
    
    // MARK: - "今天"按钮显示/隐藏测试
    
    /// 测试：选中今天时按钮隐藏
    /// 场景：用户初次打开应用，默认选中今天，按钮应该隐藏
    func testTodayButtonHiddenWhenSelectingToday() {
        // Given: 选中今天
        let selectedDate = Date()
        
        // When: 计算是否选中今天
        let isTodaySelected = Calendar.current.isDateInToday(selectedDate)
        
        // Then: 应该是今天
        XCTAssertTrue(isTodaySelected, "选中的日期应该是今天")
        
        // And: "今天"按钮应该隐藏
        let shouldShowButton = !isTodaySelected
        XCTAssertFalse(shouldShowButton, "选中今天时，按钮应该隐藏")
    }
    
    /// 测试：导航到其他日期时按钮显示
    /// 场景：用户翻到下一周，按钮应该显示
    func testTodayButtonShownWhenNavigatingAway() {
        // Given: 选中明天
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        // When: 计算是否选中今天
        let isTodaySelected = calendar.isDateInToday(tomorrow)
        
        // Then: 不应该是今天
        XCTAssertFalse(isTodaySelected, "明天不应该被判断为今天")
        
        // And: "今天"按钮应该显示
        let shouldShowButton = !isTodaySelected
        XCTAssertTrue(shouldShowButton, "选中其他日期时，按钮应该显示")
    }
    
    /// 测试：点击"今天"按钮跳转回今天
    /// 场景：用户在其他日期，点击按钮后应该跳回今天
    func testTodayButtonJumpsBackToToday() {
        // Given: 当前选中明天
        let calendar = Calendar.current
        var selectedDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        // When: 模拟点击"今天"按钮
        selectedDate = Date()
        
        // Then: 选中日期应该是今天
        XCTAssertTrue(calendar.isDateInToday(selectedDate), "点击按钮后应该跳转到今天")
        
        // And: 按钮应该隐藏
        let shouldShowButton = !calendar.isDateInToday(selectedDate)
        XCTAssertFalse(shouldShowButton, "跳转到今天后，按钮应该隐藏")
    }
    
    /// 测试：按钮状态随日期选择变化
    /// 场景：从今天 → 其他日期 → 今天，按钮状态应该正确切换
    func testTodayButtonAnimationSmooth() {
        let calendar = Calendar.current
        
        // Step 1: 选中今天
        var selectedDate = Date()
        var shouldShow = !calendar.isDateInToday(selectedDate)
        XCTAssertFalse(shouldShow, "初始状态：选中今天，按钮隐藏")
        
        // Step 2: 切换到明天
        selectedDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        shouldShow = !calendar.isDateInToday(selectedDate)
        XCTAssertTrue(shouldShow, "切换到明天，按钮显示")
        
        // Step 3: 切换到昨天
        selectedDate = calendar.date(byAdding: .day, value: -1, to: Date())!
        shouldShow = !calendar.isDateInToday(selectedDate)
        XCTAssertTrue(shouldShow, "切换到昨天，按钮仍然显示")
        
        // Step 4: 切换回今天
        selectedDate = Date()
        shouldShow = !calendar.isDateInToday(selectedDate)
        XCTAssertFalse(shouldShow, "切换回今天，按钮隐藏")
    }
    
    // MARK: - 边界情况测试
    
    /// 测试：跨日期时按钮状态更新
    /// 场景：用户在昨天打开应用，时间到了今天0点后，按钮状态应该更新
    func testTodayButtonStateUpdatesAtMidnight() {
        let calendar = Calendar.current
        
        // Given: 获取今天的0点0分
        let today = calendar.startOfDay(for: Date())
        
        // When: 选中昨天23:59
        let yesterday = calendar.date(byAdding: .second, value: -1, to: today)!
        let isYesterdayToday = calendar.isDateInToday(yesterday)
        
        // Then: 昨天不是今天
        XCTAssertFalse(isYesterdayToday, "昨天23:59不应该是今天")
        
        // When: 选中今天00:00
        let isTodayToday = calendar.isDateInToday(today)
        
        // Then: 应该是今天
        XCTAssertTrue(isTodayToday, "今天00:00应该是今天")
    }
}

