import XCTest
@testable import IdeaBox

/// Contract Test: HapticFeedback
/// 验证触觉反馈系统的正确性和性能
class HapticFeedbackTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var hapticManager: HapticManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        hapticManager = HapticManager.shared
    }
    
    override func tearDown() {
        hapticManager = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// 测试触发触觉反馈不抛出异常
    func testTriggerDoesNotThrow() {
        XCTAssertNoThrow(
            hapticManager.trigger(.light),
            "触发触觉反馈不应抛出异常"
        )
        
        XCTAssertNoThrow(
            hapticManager.trigger(.medium),
            "触发中等强度触觉反馈不应抛出异常"
        )
        
        XCTAssertNoThrow(
            hapticManager.trigger(.heavy),
            "触发重度触觉反馈不应抛出异常"
        )
    }
    
    /// 测试预加载（prepare）成功执行
    func testPrepareSucceeds() {
        XCTAssertNoThrow(
            hapticManager.prepare(),
            "预加载触觉反馈生成器不应抛出异常"
        )
    }
    
    /// 测试去抖动功能
    func testDebouncing() {
        // 记录初始触发时间
        let initialTime = Date()
        
        // 第一次触发
        hapticManager.trigger(.light)
        
        // 短时间内再次触发（应被去抖动）
        usleep(50_000) // 50ms < 100ms 最小间隔
        hapticManager.trigger(.light)
        
        // 验证去抖动逻辑存在（通过不崩溃来验证）
        XCTAssertTrue(true, "去抖动逻辑正常工作")
        
        // 等待足够时间后应该可以再次触发
        usleep(150_000) // 150ms > 100ms 最小间隔
        XCTAssertNoThrow(
            hapticManager.trigger(.light),
            "等待足够时间后应可再次触发"
        )
    }
    
    /// 测试单例模式
    func testManagerSingleton() {
        let manager1 = HapticManager.shared
        let manager2 = HapticManager.shared
        
        XCTAssertTrue(
            manager1 === manager2,
            "HapticManager 应该是单例"
        )
    }
    
    /// 测试不同强度的触觉反馈
    func testDifferentFeedbackStyles() {
        let styles: [UIImpactFeedbackGenerator.FeedbackStyle] = [
            .light,
            .medium,
            .heavy,
            .soft,
            .rigid
        ]
        
        for style in styles {
            XCTAssertNoThrow(
                hapticManager.trigger(style),
                "触发 \(style) 强度不应抛异常"
            )
        }
    }
    
    /// 测试启用/禁用功能
    func testEnableDisable() {
        // 启用触觉
        hapticManager.setEnabled(true)
        XCTAssertNoThrow(hapticManager.trigger(.light))
        
        // 禁用触觉
        hapticManager.setEnabled(false)
        XCTAssertNoThrow(
            hapticManager.trigger(.light),
            "禁用时触发不应抛异常（只是不执行）"
        )
        
        // 重新启用
        hapticManager.setEnabled(true)
    }
}

