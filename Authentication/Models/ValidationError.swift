import Foundation

/// 输入验证错误类型
enum ValidationError: Error, Equatable {
    // MARK: - Email Validation
    
    /// 邮箱为空
    case emptyEmail
    
    /// 邮箱格式无效
    case invalidEmailFormat
    
    /// 邮箱长度超限（>320个字符）
    case emailTooLong
    
    // MARK: - Password Validation
    
    /// 密码为空
    case emptyPassword
    
    /// 密码长度不足（<8个字符）
    case passwordTooShort
    
    /// 密码长度超限（>128个字符）
    case passwordTooLong
    
    /// 密码缺少大写字母
    case passwordMissingUppercase
    
    /// 密码缺少小写字母
    case passwordMissingLowercase
    
    /// 密码缺少数字
    case passwordMissingDigit
    
    /// 密码缺少特殊字符（可选要求）
    case passwordMissingSpecialChar
    
    /// 密码包含非法字符
    case passwordInvalidCharacters
    
    /// 两次密码不一致
    case passwordMismatch
    
    // MARK: - Display Properties
    
    /// 错误消息
    var message: String {
        switch self {
        // Email
        case .emptyEmail:
            return "请输入邮箱地址"
        case .invalidEmailFormat:
            return "邮箱格式不正确"
        case .emailTooLong:
            return "邮箱地址过长"
            
        // Password
        case .emptyPassword:
            return "请输入密码"
        case .passwordTooShort:
            return "密码至少需要 8 个字符"
        case .passwordTooLong:
            return "密码不能超过 128 个字符"
        case .passwordMissingUppercase:
            return "密码需要包含至少一个大写字母"
        case .passwordMissingLowercase:
            return "密码需要包含至少一个小写字母"
        case .passwordMissingDigit:
            return "密码需要包含至少一个数字"
        case .passwordMissingSpecialChar:
            return "密码需要包含至少一个特殊字符"
        case .passwordInvalidCharacters:
            return "密码包含非法字符"
        case .passwordMismatch:
            return "两次输入的密码不一致"
        }
    }
    
    /// 字段名称（用于关联到具体输入框）
    var fieldName: String {
        switch self {
        case .emptyEmail, .invalidEmailFormat, .emailTooLong:
            return "email"
        case .emptyPassword, .passwordTooShort, .passwordTooLong,
             .passwordMissingUppercase, .passwordMissingLowercase,
             .passwordMissingDigit, .passwordMissingSpecialChar,
             .passwordInvalidCharacters, .passwordMismatch:
            return "password"
        }
    }
    
    /// 是否为邮箱相关错误
    var isEmailError: Bool {
        return fieldName == "email"
    }
    
    /// 是否为密码相关错误
    var isPasswordError: Bool {
        return fieldName == "password"
    }
}

// MARK: - LocalizedError Conformance

extension ValidationError: LocalizedError {
    var errorDescription: String? {
        return message
    }
}

