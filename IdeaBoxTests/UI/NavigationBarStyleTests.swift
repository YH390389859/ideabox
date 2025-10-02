import XCTest
@testable import IdeaBox

/// Contract Test: NavigationBarStyle
/// 验证导航栏样式符合 Apple HIG 规范
class NavigationBarStyleTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var style: AppleNavigationBarStyle!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        style = AppleNavigationBarStyle()
    }
    
    override func tearDown() {
        style = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// 测试按钮尺寸符合 Apple HIG 最小触摸目标要求（44x44pt）
    func testButtonSizeCompliesWithHIG() {
        let buttonSize = style.buttonSize
        
        XCTAssertGreaterThanOrEqual(
            buttonSize,
            44,
            "按钮尺寸必须 ≥ 44pt 以符合 Apple HIG"
        )
    }
    
    /// 测试动画时长在推荐范围内（0.2-0.4 秒）
    func testAnimationDurationInRecommendedRange() {
        let duration = style.animationDuration
        
        XCTAssertGreaterThanOrEqual(
            duration,
            0.2,
            "动画时长应 ≥ 0.2 秒"
        )
        
        XCTAssertLessThanOrEqual(
            duration,
            0.4,
            "动画时长应 ≤ 0.4 秒以保持流畅感"
        )
    }
    
    /// 测试导航栏高度足以容纳内容
    func testBarHeightAccommodatesContent() {
        let barHeight = style.barHeight
        let buttonSize = style.buttonSize
        let verticalPadding = style.verticalPadding
        
        let minHeight = buttonSize + (verticalPadding * 2)
        
        XCTAssertGreaterThanOrEqual(
            barHeight,
            minHeight,
            "导航栏高度必须容纳按钮和内边距"
        )
    }
    
    /// 测试毛玻璃背景材质存在
    func testBackgroundMaterialExists() {
        let material = style.backgroundMaterial
        
        // Material 是结构体，验证可以访问即可
        XCTAssertNotNil(material, "背景材质必须定义")
    }
    
    /// 测试主题色定义
    func testAccentColorDefined() {
        let accentColor = style.accentColor
        
        XCTAssertNotNil(accentColor, "主题色必须定义")
    }
    
    /// 测试图标尺寸合理
    func testIconSizeReasonable() {
        let iconSize = style.iconSize
        
        XCTAssertGreaterThan(iconSize, 16, "图标尺寸应 > 16pt")
        XCTAssertLessThan(iconSize, 32, "图标尺寸应 < 32pt 以保持平衡")
    }
    
    /// 测试圆角半径为按钮尺寸的一半（完全圆角）
    func testCornerRadiusIsHalfButtonSize() {
        let buttonSize = style.buttonSize
        let cornerRadius = style.buttonCornerRadius
        
        XCTAssertEqual(
            cornerRadius,
            buttonSize / 2,
            accuracy: 0.1,
            "圆角半径应为按钮尺寸的一半以实现半圆效果"
        )
    }
}

