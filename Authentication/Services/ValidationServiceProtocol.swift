import Foundation

/// 输入验证服务协议
/// 负责验证用户输入（邮箱、密码等）
protocol ValidationServiceProtocol {
    // MARK: - Email Validation
    
    /// 验证邮箱格式
    /// - Parameter email: 邮箱地址
    /// - Returns: 验证结果（成功返回 nil，失败返回 ValidationError）
    func validateEmail(_ email: String) -> ValidationError?
    
    // MARK: - Password Validation
    
    /// 验证密码格式
    /// - Parameter password: 密码
    /// - Returns: 验证结果（成功返回 nil，失败返回 ValidationError）
    func validatePassword(_ password: String) -> ValidationError?
    
    /// 评估密码强度
    /// - Parameter password: 密码
    /// - Returns: 密码强度等级
    func evaluatePasswordStrength(_ password: String) -> PasswordStrength
    
    /// 验证两次密码是否一致
    /// - Parameters:
    ///   - password: 密码
    ///   - confirmation: 确认密码
    /// - Returns: 验证结果（成功返回 nil，失败返回 ValidationError）
    func validatePasswordMatch(_ password: String, _ confirmation: String) -> ValidationError?
    
    // MARK: - Combined Validation
    
    /// 批量验证（注册时使用）
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - password: 密码
    ///   - confirmation: 确认密码
    /// - Returns: 所有验证错误的数组（成功返回空数组）
    func validateSignUp(email: String, password: String, confirmation: String) -> [ValidationError]
    
    /// 批量验证（登录时使用）
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - password: 密码
    /// - Returns: 所有验证错误的数组（成功返回空数组）
    func validateLogin(email: String, password: String) -> [ValidationError]
    
    /// 批量验证（忘记密码时使用）
    /// - Parameter email: 邮箱地址
    /// - Returns: 验证结果（成功返回 nil，失败返回 ValidationError）
    func validateForgotPassword(email: String) -> ValidationError?
}

// MARK: - Default Implementations

extension ValidationServiceProtocol {
    /// 验证邮箱格式（默认实现）
    func validateEmail(_ email: String) -> ValidationError? {
        // 检查是否为空
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .emptyEmail
        }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查长度
        guard trimmedEmail.count <= 320 else {
            return .emailTooLong
        }
        
        // 正则表达式验证邮箱格式
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            return .invalidEmailFormat
        }
        
        return nil
    }
    
    /// 验证密码格式（默认实现）
    func validatePassword(_ password: String) -> ValidationError? {
        // 检查是否为空
        guard !password.isEmpty else {
            return .emptyPassword
        }
        
        // 检查长度
        guard password.count >= 8 else {
            return .passwordTooShort
        }
        
        guard password.count <= 128 else {
            return .passwordTooLong
        }
        
        // 检查是否包含大写字母
        guard password.range(of: "[A-Z]", options: .regularExpression) != nil else {
            return .passwordMissingUppercase
        }
        
        // 检查是否包含小写字母
        guard password.range(of: "[a-z]", options: .regularExpression) != nil else {
            return .passwordMissingLowercase
        }
        
        // 检查是否包含数字
        guard password.range(of: "[0-9]", options: .regularExpression) != nil else {
            return .passwordMissingDigit
        }
        
        return nil
    }
    
    /// 评估密码强度（默认实现）
    func evaluatePasswordStrength(_ password: String) -> PasswordStrength {
        return PasswordStrength.evaluate(password)
    }
    
    /// 验证两次密码是否一致（默认实现）
    func validatePasswordMatch(_ password: String, _ confirmation: String) -> ValidationError? {
        guard password == confirmation else {
            return .passwordMismatch
        }
        return nil
    }
    
    /// 批量验证注册输入（默认实现）
    func validateSignUp(email: String, password: String, confirmation: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // 验证邮箱
        if let emailError = validateEmail(email) {
            errors.append(emailError)
        }
        
        // 验证密码
        if let passwordError = validatePassword(password) {
            errors.append(passwordError)
        }
        
        // 验证密码匹配
        if let matchError = validatePasswordMatch(password, confirmation) {
            errors.append(matchError)
        }
        
        return errors
    }
    
    /// 批量验证登录输入（默认实现）
    func validateLogin(email: String, password: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // 验证邮箱
        if let emailError = validateEmail(email) {
            errors.append(emailError)
        }
        
        // 验证密码不为空
        if password.isEmpty {
            errors.append(.emptyPassword)
        }
        
        return errors
    }
    
    /// 验证忘记密码输入（默认实现）
    func validateForgotPassword(email: String) -> ValidationError? {
        return validateEmail(email)
    }
}

