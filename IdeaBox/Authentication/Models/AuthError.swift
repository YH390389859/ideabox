import Foundation
import FirebaseAuth

/// 认证错误类型
enum AuthError: Error {
    // MARK: - Email/Password Errors
    
    /// 邮箱格式无效
    case invalidEmail
    
    /// 密码格式无效（不符合强度要求）
    case invalidPassword(reason: String)
    
    /// 邮箱已被注册
    case emailAlreadyInUse
    
    /// 用户未找到
    case userNotFound
    
    /// 密码错误
    case wrongPassword
    
    /// 邮箱未验证
    case emailNotVerified
    
    // MARK: - Session Errors
    
    /// 会话已过期
    case sessionExpired
    
    /// 无效的令牌
    case invalidToken
    
    /// 刷新令牌失败
    case tokenRefreshFailed
    
    // MARK: - Account Security Errors
    
    /// 账号已被禁用
    case accountDisabled
    
    /// 登录尝试次数过多（需要等待）
    case tooManyRequests(waitTime: TimeInterval)
    
    /// 操作被拒绝（需要重新登录）
    case operationNotAllowed
    
    // MARK: - Network Errors
    
    /// 网络连接失败
    case networkError
    
    /// 网络请求超时
    case timeout
    
    // MARK: - System Errors
    
    /// Keychain 访问失败
    case keychainError
    
    /// Firebase 初始化失败
    case firebaseNotConfigured
    
    /// 未知错误
    case unknown(Error)
    
    // MARK: - Initialization from Firebase Error
    
    /// 从 Firebase Auth Error 映射
    init(from firebaseError: Error) {
        let nsError = firebaseError as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            self = .unknown(firebaseError)
            return
        }
        
        switch code {
        case .invalidEmail:
            self = .invalidEmail
        case .emailAlreadyInUse:
            self = .emailAlreadyInUse
        case .userNotFound:
            self = .userNotFound
        case .wrongPassword:
            self = .wrongPassword
        case .weakPassword:
            self = .invalidPassword(reason: "密码强度不足")
        case .userDisabled:
            self = .accountDisabled
        case .tooManyRequests:
            self = .tooManyRequests(waitTime: 15 * 60) // 15分钟
        case .operationNotAllowed:
            self = .operationNotAllowed
        case .networkError:
            self = .networkError
        default:
            self = .unknown(firebaseError)
        }
    }
    
    // MARK: - Display Properties
    
    /// 错误标题
    var title: String {
        switch self {
        case .invalidEmail:
            return "邮箱格式错误"
        case .invalidPassword:
            return "密码格式错误"
        case .emailAlreadyInUse:
            return "邮箱已被使用"
        case .userNotFound:
            return "用户不存在"
        case .wrongPassword:
            return "密码错误"
        case .emailNotVerified:
            return "邮箱未验证"
        case .sessionExpired:
            return "会话已过期"
        case .invalidToken:
            return "令牌无效"
        case .tokenRefreshFailed:
            return "刷新令牌失败"
        case .accountDisabled:
            return "账号已被禁用"
        case .tooManyRequests:
            return "操作频繁"
        case .operationNotAllowed:
            return "操作未允许"
        case .networkError:
            return "网络连接失败"
        case .timeout:
            return "请求超时"
        case .keychainError:
            return "钥匙串访问失败"
        case .firebaseNotConfigured:
            return "服务未配置"
        case .unknown:
            return "未知错误"
        }
    }
    
    /// 错误描述（用户友好）
    var message: String {
        switch self {
        case .invalidEmail:
            return "请输入有效的邮箱地址"
        case .invalidPassword(let reason):
            return reason
        case .emailAlreadyInUse:
            return "该邮箱已被注册，请直接登录或使用其他邮箱"
        case .userNotFound:
            return "该邮箱尚未注册，请先注册账号"
        case .wrongPassword:
            return "密码错误，请重试或点击【忘记密码】重置"
        case .emailNotVerified:
            return "请先验证您的邮箱地址，验证邮件已发送至您的邮箱"
        case .sessionExpired:
            return "登录已过期，请重新登录"
        case .invalidToken:
            return "登录状态无效，请重新登录"
        case .tokenRefreshFailed:
            return "刷新登录状态失败，请重新登录"
        case .accountDisabled:
            return "您的账号已被禁用，请联系客服"
        case .tooManyRequests(let waitTime):
            let minutes = Int(waitTime / 60)
            return "登录尝试次数过多，请在 \(minutes) 分钟后重试"
        case .operationNotAllowed:
            return "该操作暂不支持，请联系客服"
        case .networkError:
            return "网络连接失败，请检查您的网络设置"
        case .timeout:
            return "请求超时，请稍后重试"
        case .keychainError:
            return "无法保存登录信息，请检查设备安全设置"
        case .firebaseNotConfigured:
            return "服务配置错误，请联系技术支持"
        case .unknown(let error):
            return "发生未知错误：\(error.localizedDescription)"
        }
    }
    
    /// 错误的恢复建议
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "请检查邮箱格式（例如：user@example.com）"
        case .invalidPassword:
            return "密码必须至少8位，包含大小写字母和数字"
        case .emailAlreadyInUse:
            return "尝试登录或使用【忘记密码】功能"
        case .userNotFound:
            return "请先注册账号"
        case .wrongPassword:
            return "检查密码或使用【忘记密码】重置"
        case .emailNotVerified:
            return "查看邮箱验证邮件，或点击【重新发送】"
        case .sessionExpired:
            return "请重新登录"
        case .networkError:
            return "检查网络连接后重试"
        case .tooManyRequests:
            return "请稍后再试，或联系客服"
        default:
            return nil
        }
    }
    
    /// 是否可重试
    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .tokenRefreshFailed:
            return true
        default:
            return false
        }
    }
    
    /// 是否需要重新登录
    var requiresReAuthentication: Bool {
        switch self {
        case .sessionExpired, .invalidToken, .tokenRefreshFailed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Equatable Conformance

extension AuthError: Equatable {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        // Email/Password Errors
        case (.invalidEmail, .invalidEmail):
            return true
        case let (.invalidPassword(reason1), .invalidPassword(reason2)):
            return reason1 == reason2
        case (.emailAlreadyInUse, .emailAlreadyInUse):
            return true
        case (.userNotFound, .userNotFound):
            return true
        case (.wrongPassword, .wrongPassword):
            return true
        case (.emailNotVerified, .emailNotVerified):
            return true
            
        // Session Errors
        case (.sessionExpired, .sessionExpired):
            return true
        case (.invalidToken, .invalidToken):
            return true
        case (.tokenRefreshFailed, .tokenRefreshFailed):
            return true
            
        // Account Security Errors
        case (.accountDisabled, .accountDisabled):
            return true
        case let (.tooManyRequests(time1), .tooManyRequests(time2)):
            return time1 == time2
        case (.operationNotAllowed, .operationNotAllowed):
            return true
            
        // Network Errors
        case (.networkError, .networkError):
            return true
        case (.timeout, .timeout):
            return true
            
        // System Errors
        case (.keychainError, .keychainError):
            return true
        case (.firebaseNotConfigured, .firebaseNotConfigured):
            return true
        case let (.unknown(error1), .unknown(error2)):
            // 比较错误的本地化描述
            return error1.localizedDescription == error2.localizedDescription
            
        default:
            return false
        }
    }
}

// MARK: - LocalizedError Conformance

extension AuthError: LocalizedError {
    var errorDescription: String? {
        return message
    }
    
    var failureReason: String? {
        return title
    }
    
    var recoverySuggestionDescription: String? {
        return recoverySuggestion
    }
}

