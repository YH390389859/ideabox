import SwiftUI

// MARK: - Protocol

protocol NavigationBarStyleProtocol {
    // MARK: - Background
    var backgroundMaterial: Material { get }
    var backgroundOpacity: CGFloat { get }
    
    // MARK: - Colors
    var accentColor: Color { get }
    var iconColor: Color { get }
    var selectedIconColor: Color { get }
    var buttonBackgroundColor: Color { get }
    var shadowColor: Color { get }
    
    // MARK: - Dimensions
    var barHeight: CGFloat { get }
    var horizontalPadding: CGFloat { get }
    var verticalPadding: CGFloat { get }
    var buttonSize: CGFloat { get }
    var buttonCornerRadius: CGFloat { get }
    var buttonSpacing: CGFloat { get }
    var iconSize: CGFloat { get }
    var shadowRadius: CGFloat { get }
    var shadowOffset: CGSize { get }
    
    // MARK: - Animation
    var animationDuration: TimeInterval { get }
    var animationCurve: Animation { get }
    var buttonPressAnimation: Animation { get }
}

// MARK: - Apple Standard Implementation

/// Apple 标准导航栏样式
struct AppleNavigationBarStyle: NavigationBarStyleProtocol {
    // MARK: - Background
    
    let backgroundMaterial: Material = .ultraThinMaterial
    let backgroundOpacity: CGFloat = 0.95
    
    // MARK: - Colors
    
    let accentColor: Color = Color("NavigationAccent")
    let iconColor: Color = .primary
    let selectedIconColor: Color = Color("NavigationAccent")
    let buttonBackgroundColor: Color = .white
    let shadowColor: Color = Color.black.opacity(0.15)
    
    // MARK: - Dimensions (符合 Apple HIG)
    
    let barHeight: CGFloat = 84
    let horizontalPadding: CGFloat = 16
    let verticalPadding: CGFloat = 25
    let buttonSize: CGFloat = 44        // HIG 最小触摸目标
    let buttonCornerRadius: CGFloat = 22 // 半圆形 (44/2)
    let buttonSpacing: CGFloat = 12
    let iconSize: CGFloat = 22
    let shadowRadius: CGFloat = 4
    let shadowOffset: CGSize = CGSize(width: 0, height: 0)
    
    // MARK: - Animation (符合 Apple 动画标准)
    
    let animationDuration: TimeInterval = 0.25
    let animationCurve: Animation = .easeInOut(duration: 0.25)
    let buttonPressAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.6)
}

