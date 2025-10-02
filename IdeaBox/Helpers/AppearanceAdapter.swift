import SwiftUI

// MARK: - Protocol

protocol AppearanceAdaptable {
    func adaptToColorScheme(_ scheme: ColorScheme) -> Self
    func color(for scheme: ColorScheme, light: Color, dark: Color) -> Color
    func adaptToDynamicType(_ category: ContentSizeCategory) -> Self
    func scaleFactor(for category: ContentSizeCategory) -> CGFloat
    func adaptToReduceMotion(_ enabled: Bool) -> Self
    func adaptToIncreaseContrast(_ enabled: Bool) -> Self
    func provideAccessibilityLabels() -> [String: String]
}

// MARK: - Appearance Adapter

/// 外观适配助手
struct AppearanceAdapter: AppearanceAdaptable {
    // MARK: - State
    
    var colorScheme: ColorScheme = .light
    var sizeCategory: ContentSizeCategory = .medium
    var reduceMotion: Bool = false
    var increaseContrast: Bool = false
    
    // MARK: - Color Scheme Adaptation
    
    func adaptToColorScheme(_ scheme: ColorScheme) -> AppearanceAdapter {
        var adapter = self
        adapter.colorScheme = scheme
        return adapter
    }
    
    func color(for scheme: ColorScheme, light: Color, dark: Color) -> Color {
        scheme == .light ? light : dark
    }
    
    // MARK: - Dynamic Type Adaptation
    
    func adaptToDynamicType(_ category: ContentSizeCategory) -> AppearanceAdapter {
        var adapter = self
        adapter.sizeCategory = category
        return adapter
    }
    
    func scaleFactor(for category: ContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium, .large:
            return 1.0
        case .extraLarge:
            return 1.1
        case .extraExtraLarge:
            return 1.2
        case .extraExtraExtraLarge:
            return 1.3
        case .accessibilityMedium:
            return 1.4
        case .accessibilityLarge:
            return 1.6
        case .accessibilityExtraLarge:
            return 1.8
        case .accessibilityExtraExtraLarge:
            return 2.0
        case .accessibilityExtraExtraExtraLarge:
            return 2.2
        @unknown default:
            return 1.0
        }
    }
    
    // MARK: - Accessibility Adaptation
    
    func adaptToReduceMotion(_ enabled: Bool) -> AppearanceAdapter {
        var adapter = self
        adapter.reduceMotion = enabled
        return adapter
    }
    
    func adaptToIncreaseContrast(_ enabled: Bool) -> AppearanceAdapter {
        var adapter = self
        adapter.increaseContrast = enabled
        return adapter
    }
    
    func provideAccessibilityLabels() -> [String: String] {
        [
            "today": "今天按钮",
            "add": "添加按钮",
            "profile": "个人中心按钮",
            "navigationBar": "底部导航栏"
        ]
    }
    
    // MARK: - Computed Properties
    
    /// 当前动画时长
    var animationDuration: TimeInterval {
        reduceMotion ? 0.1 : 0.25
    }
    
    /// 当前对比度增强因子
    var contrastMultiplier: CGFloat {
        increaseContrast ? 1.2 : 1.0
    }
}

