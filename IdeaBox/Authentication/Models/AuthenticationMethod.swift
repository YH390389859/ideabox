import Foundation

/// 认证方式枚举
enum AuthenticationMethod: String, Codable, CaseIterable, Equatable {
    /// 邮箱/密码登录 (Phase 1 ✅)
    case email = "email"
    
    /// Apple Sign In (Phase 2 ⏸️)
    case apple = "apple"
    
    // MARK: - Display Properties
    
    /// 方式的显示名称
    var displayName: String {
        switch self {
        case .email:
            return "邮箱登录"
        case .apple:
            return "Apple Sign In"
        }
    }
    
    /// 方式的图标名称（SF Symbols）
    var iconName: String {
        switch self {
        case .email:
            return "envelope.fill"
        case .apple:
            return "applelogo"
        }
    }
    
    /// 方式的描述
    var description: String {
        switch self {
        case .email:
            return "使用邮箱和密码登录"
        case .apple:
            return "使用 Apple ID 快速登录"
        }
    }
    
    // MARK: - Feature Flags
    
    /// 该方式是否在当前版本可用
    var isAvailable: Bool {
        switch self {
        case .email:
            return true  // Phase 1: 邮箱登录已实现
        case .apple:
            return false  // Phase 2: Apple Sign In 暂未实现
        }
    }
    
    /// 该方式是否需要邮箱验证
    var requiresEmailVerification: Bool {
        switch self {
        case .email:
            return true
        case .apple:
            return false  // Apple 已验证
        }
    }
    
    /// 该方式是否支持密码重置
    var supportsPasswordReset: Bool {
        switch self {
        case .email:
            return true
        case .apple:
            return false  // Apple 由苹果管理
        }
    }
    
    // MARK: - Static Helpers
    
    /// 获取所有可用的认证方式
    static var available: [AuthenticationMethod] {
        return allCases.filter { $0.isAvailable }
    }
    
    /// 获取默认认证方式
    static var `default`: AuthenticationMethod {
        return .email
    }
}

