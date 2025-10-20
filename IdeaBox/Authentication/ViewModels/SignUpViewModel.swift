import Foundation
import Combine

/// 注册页面 ViewModel
@MainActor
final class SignUpViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 邮箱输入
    @Published var email: String = ""
    
    /// 密码输入
    @Published var password: String = ""
    
    /// 确认密码输入
    @Published var confirmPassword: String = ""
    
    /// 是否同意服务条款
    @Published var agreedToTerms: Bool = false
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 错误消息
    @Published var errorMessage: String?
    
    /// 是否显示错误
    @Published var showError: Bool = false
    
    /// 注册成功（用于显示验证邮件提示）
    @Published var isSignedUp: Bool = false
    
    /// 是否显示验证邮件提示
    @Published var showEmailVerificationAlert: Bool = false
    
    // MARK: - Computed Properties
    
    /// 邮箱验证错误
    var emailError: String? {
        guard !email.isEmpty else { return nil }
        if let error = validationService.validateEmail(email) {
            return error.message
        }
        return nil
    }
    
    /// 密码强度
    var passwordStrength: PasswordStrength {
        guard !password.isEmpty else { return .veryWeak }
        return validationService.evaluatePasswordStrength(password)
    }
    
    /// 密码验证错误
    var passwordError: String? {
        guard !password.isEmpty else { return nil }
        if let error = validationService.validatePassword(password) {
            return error.message
        }
        return nil
    }
    
    /// 确认密码验证错误
    var confirmPasswordError: String? {
        guard !confirmPassword.isEmpty else { return nil }
        if let error = validationService.validatePasswordMatch(password, confirmPassword) {
            return error.message
        }
        return nil
    }
    
    /// 表单是否有效（可以提交）
    var isFormValid: Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               agreedToTerms &&
               validationService.validateEmail(email) == nil &&
               validationService.validatePassword(password) == nil &&
               validationService.validatePasswordMatch(password, confirmPassword) == nil
    }
    
    // MARK: - Services
    
    private let authService: AuthenticationServiceProtocol
    private let validationService: ValidationServiceProtocol
    
    // MARK: - Initialization
    
    init(
        authService: AuthenticationServiceProtocol = AuthenticationService(),
        validationService: ValidationServiceProtocol = ValidationService()
    ) {
        self.authService = authService
        self.validationService = validationService
    }
    
    // MARK: - Actions
    
    /// 注册
    func signUp() async {
        // 验证输入
        let errors = validationService.validateSignUp(
            email: email,
            password: password,
            confirmation: confirmPassword
        )
        
        if !errors.isEmpty {
            errorMessage = errors.first?.message
            showError = true
            return
        }
        
        guard agreedToTerms else {
            errorMessage = "请同意服务条款和隐私政策"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // 执行注册
            let user = try await authService.signUp(
                email: email,
                password: password
            )
            
            // 发送验证邮件
            try await authService.sendEmailVerification(to: user)
            
            // 注册成功
            isSignedUp = true
            showEmailVerificationAlert = true
            isLoading = false
            
        } catch let error as AuthError {
            isLoading = false
            errorMessage = error.message
            showError = true
        } catch {
            isLoading = false
            errorMessage = "注册失败，请稍后重试"
            showError = true
        }
    }
    
    /// 重新发送验证邮件
    func resendVerificationEmail() async {
        guard let currentUser = authService.getCurrentUser() else {
            errorMessage = "未找到当前用户"
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            try await authService.sendEmailVerification(to: currentUser)
            errorMessage = "验证邮件已重新发送"
            showError = false
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "发送验证邮件失败，请稍后重试"
            showError = true
        }
    }
    
    /// 清除错误
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

