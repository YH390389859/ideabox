import Foundation
import SwiftUI

/// 应用主题模式
enum AppTheme: String, Codable, CaseIterable, Equatable {
    /// 浅色模式
    case light = "light"
    
    /// 深色模式
    case dark = "dark"
    
    /// 跟随系统
    case system = "system"
    
    // MARK: - Display Properties
    
    /// 主题显示名称
    var displayName: String {
        switch self {
        case .light:
            return "浅色模式"
        case .dark:
            return "深色模式"
        case .system:
            return "跟随系统"
        }
    }
    
    /// 主题图标（SF Symbols）
    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
    
    /// 主题描述
    var description: String {
        switch self {
        case .light:
            return "始终使用浅色主题"
        case .dark:
            return "始终使用深色主题"
        case .system:
            return "跟随系统外观设置"
        }
    }
    
    // MARK: - Color Scheme Conversion
    
    /// 转换为 SwiftUI ColorScheme（如果需要覆盖）
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil  // 不覆盖，跟随系统
        }
    }
}

