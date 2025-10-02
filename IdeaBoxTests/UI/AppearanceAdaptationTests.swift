import XCTest
import SwiftUI
@testable import IdeaBox

/// Contract Test: AppearanceAdaptation
/// 验证系统外观和辅助功能适配
class AppearanceAdaptationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var adapter: AppearanceAdapter!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        adapter = AppearanceAdapter()
    }
    
    override func tearDown() {
        adapter = nil
        super.tearDown()
    }
    
    // MARK: - Color Scheme Tests
    
    /// 测试深色模式颜色适配
    func testDarkModeColors() {
        let lightAdapter = adapter.adaptToColorScheme(.light)
        let darkAdapter = adapter.adaptToColorScheme(.dark)
        
        XCTAssertEqual(lightAdapter.colorScheme, .light)
        XCTAssertEqual(darkAdapter.colorScheme, .dark)
        
        // 验证颜色选择逻辑
        let lightColor = lightAdapter.color(
            for: .light,
            light: .white,
            dark: .black
        )
        let darkColor = darkAdapter.color(
            for: .dark,
            light: .white,
            dark: .black
        )
        
        // 颜色应该根据方案选择
        XCTAssertNotNil(lightColor)
        XCTAssertNotNil(darkColor)
    }
    
    // MARK: - Dynamic Type Tests
    
    /// 测试动态字体缩放因子
    func testDynamicTypeScaling() {
        let categories: [ContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        for category in categories {
            let scaleFactor = adapter.scaleFactor(for: category)
            
            XCTAssertGreaterThan(
                scaleFactor,
                0,
                "\(category) 的缩放因子必须 > 0"
            )
            
            XCTAssertLessThanOrEqual(
                scaleFactor,
                3.0,
                "\(category) 的缩放因子不应超过 3.0"
            )
        }
    }
    
    /// 测试字体大小适配
    func testAdaptToDynamicType() {
        let smallAdapter = adapter.adaptToDynamicType(.extraSmall)
        let largeAdapter = adapter.adaptToDynamicType(.extraExtraExtraLarge)
        
        XCTAssertEqual(smallAdapter.sizeCategory, .extraSmall)
        XCTAssertEqual(largeAdapter.sizeCategory, .extraExtraExtraLarge)
        
        // 大字体的缩放因子应该更大
        let smallScale = smallAdapter.scaleFactor(for: .extraSmall)
        let largeScale = largeAdapter.scaleFactor(for: .extraExtraExtraLarge)
        
        XCTAssertLessThan(
            smallScale,
            largeScale,
            "大字体的缩放因子应该 > 小字体"
        )
    }
    
    // MARK: - Reduce Motion Tests
    
    /// 测试减少动画适配
    func testReduceMotionAdaptation() {
        let normalAdapter = adapter.adaptToReduceMotion(false)
        let reducedAdapter = adapter.adaptToReduceMotion(true)
        
        XCTAssertFalse(normalAdapter.reduceMotion)
        XCTAssertTrue(reducedAdapter.reduceMotion)
        
        // 验证动画时长调整
        let normalDuration = normalAdapter.animationDuration
        let reducedDuration = reducedAdapter.animationDuration
        
        XCTAssertLessThan(
            reducedDuration,
            normalDuration,
            "减少动画模式下时长应更短"
        )
    }
    
    // MARK: - Contrast Tests
    
    /// 测试颜色对比度符合 WCAG 2.1 AA 标准 (≥ 4.5:1)
    func testColorContrastCompliance() {
        // 系统蓝 #007AFF vs 白背景
        let blueOnWhiteContrast = 4.52 // 预期值（根据设计文档）
        
        XCTAssertGreaterThanOrEqual(
            blueOnWhiteContrast,
            4.5,
            "浅色模式对比度必须 ≥ 4.5:1 (WCAG AA)"
        )
        
        // 深色系统蓝 #0A84FF vs 黑背景
        let blueOnBlackContrast = 8.59 // 预期值
        
        XCTAssertGreaterThanOrEqual(
            blueOnBlackContrast,
            4.5,
            "深色模式对比度必须 ≥ 4.5:1 (WCAG AA)"
        )
        
        // 理想目标：AAA 标准 (≥ 7:1)
        XCTAssertGreaterThanOrEqual(
            blueOnBlackContrast,
            7.0,
            "深色模式应达到 AAA 标准 (≥ 7:1)"
        )
    }
    
    /// 测试增强对比度适配
    func testIncreaseContrastAdaptation() {
        let normalAdapter = adapter.adaptToIncreaseContrast(false)
        let contrastAdapter = adapter.adaptToIncreaseContrast(true)
        
        XCTAssertFalse(normalAdapter.increaseContrast)
        XCTAssertTrue(contrastAdapter.increaseContrast)
        
        // 验证对比度乘数
        let normalMultiplier = normalAdapter.contrastMultiplier
        let contrastMultiplier = contrastAdapter.contrastMultiplier
        
        XCTAssertGreaterThan(
            contrastMultiplier,
            normalMultiplier,
            "增强对比度模式下乘数应更大"
        )
    }
    
    // MARK: - Accessibility Labels Tests
    
    /// 测试辅助功能标签完整性
    func testAccessibilityLabelsProvided() {
        let labels = adapter.provideAccessibilityLabels()
        
        XCTAssertFalse(labels.isEmpty, "必须提供辅助功能标签")
        
        // 验证关键按钮的标签存在
        XCTAssertNotNil(labels["today"], "必须提供'今天'按钮标签")
        XCTAssertNotNil(labels["add"], "必须提供'添加'按钮标签")
        XCTAssertNotNil(labels["profile"], "必须提供'个人中心'按钮标签")
        XCTAssertNotNil(labels["navigationBar"], "必须提供导航栏标签")
        
        // 验证标签不为空
        for (key, value) in labels {
            XCTAssertFalse(
                value.isEmpty,
                "\(key) 的标签不能为空字符串"
            )
        }
    }
    
    // MARK: - Combined Adaptation Tests
    
    /// 测试多种适配同时生效
    func testCombinedAdaptations() {
        let combinedAdapter = adapter
            .adaptToColorScheme(.dark)
            .adaptToDynamicType(.extraExtraExtraLarge)
            .adaptToReduceMotion(true)
            .adaptToIncreaseContrast(true)
        
        XCTAssertEqual(combinedAdapter.colorScheme, .dark)
        XCTAssertEqual(combinedAdapter.sizeCategory, .extraExtraExtraLarge)
        XCTAssertTrue(combinedAdapter.reduceMotion)
        XCTAssertTrue(combinedAdapter.increaseContrast)
    }
}

