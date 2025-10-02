import SwiftUI

/// 导航栏中的单个导航项
struct NavigationItem: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let selectedIcon: String
    let action: () -> Void
    var isVisible: Bool = true
    var badge: Int? = nil
    
    // MARK: - Equatable
    
    /// Equatable conformance (忽略 action 闭包)
    static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.icon == rhs.icon &&
        lhs.selectedIcon == rhs.selectedIcon &&
        lhs.isVisible == rhs.isVisible &&
        lhs.badge == rhs.badge
    }
}

// MARK: - Validation

extension NavigationItem {
    /// 验证导航项配置是否有效
    func validate() -> [String] {
        var errors: [String] = []
        
        // 验证 ID 不为空
        if id.isEmpty {
            errors.append("Navigation item ID cannot be empty")
        }
        
        // 验证标题不为空
        if title.isEmpty {
            errors.append("Navigation item title cannot be empty (required for VoiceOver)")
        }
        
        // 验证图标名称格式（基础检查）
        if icon.isEmpty {
            errors.append("Navigation item icon cannot be empty")
        }
        if selectedIcon.isEmpty {
            errors.append("Navigation item selectedIcon cannot be empty")
        }
        
        // 验证徽章数量范围
        if let badge = badge, badge < 0 {
            errors.append("Badge count cannot be negative")
        }
        
        return errors
    }
}

// MARK: - Mock Data

#if DEBUG
extension NavigationItem {
    /// 测试用的今天按钮
    static var mockToday: NavigationItem {
        NavigationItem(
            id: "today",
            title: "今天",
            icon: "calendar.badge.clock",
            selectedIcon: "calendar.badge.clock.fill",
            action: { print("Today tapped") }
        )
    }
    
    /// 测试用的添加按钮
    static var mockAdd: NavigationItem {
        NavigationItem(
            id: "add",
            title: "添加",
            icon: "plus.circle.fill",
            selectedIcon: "plus.circle.fill",
            action: { print("Add tapped") }
        )
    }
    
    /// 测试用的个人按钮
    static var mockProfile: NavigationItem {
        NavigationItem(
            id: "profile",
            title: "个人中心",
            icon: "person.crop.circle",
            selectedIcon: "person.crop.circle.fill",
            action: { print("Profile tapped") }
        )
    }
    
    /// 完整的导航项集合
    static var mockItems: [NavigationItem] {
        [mockToday, mockAdd, mockProfile]
    }
}
#endif

