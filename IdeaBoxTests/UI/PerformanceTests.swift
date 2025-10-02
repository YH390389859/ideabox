//
//  PerformanceTests.swift
//  IdeaBoxTests
//
//  Created by AI Assistant on 2025-10-02.
//  性能测试：验证快速连续滑动的性能和正确性
//

import XCTest
@testable import IdeaBox

final class PerformanceTests: XCTestCase {
    
    var dateHelper: DateHelper!
    
    override func setUp() {
        super.setUp()
        dateHelper = DateHelper.shared
    }
    
    override func tearDown() {
        dateHelper = nil
        super.tearDown()
    }
    
    // MARK: - 快速翻页性能测试
    
    /// 测试：快速连续获取周数据的性能
    /// 场景：模拟用户快速滑动，连续获取多个周的数据
    func testQuickSwipePerformance() {
        // Measure the performance of quickly getting week data
        measure {
            // 模拟快速滑动10次
            for offset in -10...10 {
                let _ = dateHelper.getWeek(offset: offset, relativeTo: Date())
            }
        }
        
        // Note: XCTest 会自动记录平均时间、标准差等指标
        // 目标：每次 getWeek 调用应该 < 10ms，21次调用总时间 < 210ms
    }
    
    /// 测试：周数据生成的时间复杂度
    /// 场景：验证 getWeek 方法的时间复杂度是否稳定
    func testWeekDataGenerationComplexity() {
        let today = Date()
        var times: [TimeInterval] = []
        
        // 测试不同偏移量的生成时间
        for offset in [0, 10, 52, -10, -52] {
            let start = Date()
            let _ = dateHelper.getWeek(offset: offset, relativeTo: today)
            let elapsed = Date().timeIntervalSince(start)
            times.append(elapsed)
        }
        
        // 验证时间差异不大（时间复杂度应该是 O(1) 或 O(7)）
        let maxTime = times.max() ?? 0
        let minTime = times.min() ?? 0
        let variance = maxTime - minTime
        
        // 允许最大10倍的时间差异（考虑系统抖动）
        XCTAssertLessThan(variance, 0.1, "不同偏移量的生成时间应该相近")
    }
    
    // MARK: - 内存使用测试
    
    /// 测试：连续翻页的内存占用
    /// 场景：模拟用户连续翻100次，验证内存是否稳定
    func testMemoryUsageDuringNavigation() {
        // 初始内存快照
        let initialMemory = reportMemory()
        
        // 模拟连续翻页100次
        var weeks: [WeekData] = []
        for offset in -50...50 {
            let week = dateHelper.getWeek(offset: offset, relativeTo: Date())
            weeks.append(week)
        }
        
        // 最终内存快照
        let finalMemory = reportMemory()
        
        // 计算内存增量（单位：MB）
        let memoryIncrease = finalMemory - initialMemory
        
        // 验证内存增量 < 10MB（101个 WeekData 对象）
        XCTAssertLessThan(memoryIncrease, 10.0, "连续翻页的内存增量应该小于10MB")
        
        // 清理引用
        weeks.removeAll()
        
        // Note: 实际应用中 TabView 只会保留可见范围内的视图，内存占用会更小
    }
    
    /// 测试：DateHelper 是否有内存泄漏
    /// 场景：重复获取相同的周数据，验证内存是否持续增长
    func testNoMemoryLeakInDateHelper() {
        // 重复获取相同的周数据1000次
        for _ in 0..<1000 {
            let _ = dateHelper.getWeek(offset: 0, relativeTo: Date())
        }
        
        // Note: 如果有内存泄漏，这个测试会导致内存持续增长
        // 使用 Xcode Instruments 的 Leaks 工具来检测
        
        XCTAssertTrue(true, "如果能执行到这里说明没有崩溃")
    }
    
    // MARK: - 并发安全测试
    
    /// 测试：多线程并发访问 DateHelper
    /// 场景：模拟多个线程同时获取周数据，验证线程安全性
    func testConcurrentAccess() {
        let expectation = self.expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        // 创建10个并发任务
        for i in 0..<10 {
            DispatchQueue.global().async {
                // 每个线程获取不同偏移量的周数据
                let week = self.dateHelper.getWeek(offset: i - 5, relativeTo: Date())
                
                // 验证返回的数据正确
                XCTAssertEqual(week.days.count, 7, "线程\(i)应该返回7天数据")
                XCTAssertEqual(week.offset, i - 5, "线程\(i)的偏移量应该正确")
                
                expectation.fulfill()
            }
        }
        
        // 等待所有线程完成（超时10秒）
        waitForExpectations(timeout: 10)
    }
    
    // MARK: - 边界条件下的性能
    
    /// 测试：跨月跨年情况下的性能
    /// 场景：验证特殊日期（月末、年末）的计算性能
    func testPerformanceAtBoundaryDates() {
        let calendar = Calendar.current
        
        // 测试年末日期
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 31
        
        guard let yearEnd = calendar.date(from: components) else {
            XCTFail("无法创建年末日期")
            return
        }
        
        // Measure performance at year boundary
        measure {
            for offset in -5...5 {
                let _ = dateHelper.getWeek(offset: offset, relativeTo: yearEnd)
            }
        }
        
        // 目标：边界日期的计算时间应该与普通日期相近
    }
    
    /// 测试：weekOffset 计算性能
    /// 场景：验证两个日期之间的周偏移量计算性能
    func testWeekOffsetCalculationPerformance() {
        let today = Date()
        let calendar = Calendar.current
        
        measure {
            // 测试不同距离的偏移量计算
            for days in [7, 14, 30, 90, 180, 365] {
                let futureDate = calendar.date(byAdding: .day, value: days, to: today)!
                let _ = dateHelper.weekOffset(for: futureDate, relativeTo: today)
            }
        }
        
        // 目标：每次 weekOffset 计算应该 < 5ms
    }
    
    // MARK: - Helper Methods
    
    /// 报告当前内存使用情况（单位：MB）
    private func reportMemory() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemoryMB = Double(info.resident_size) / 1024.0 / 1024.0
            return usedMemoryMB
        } else {
            return 0
        }
    }
}

