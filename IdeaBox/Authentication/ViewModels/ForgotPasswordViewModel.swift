import Foundation
import Combine

/// 忘记密码页面 ViewModel
@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 邮箱输入
    @Published var email: String = ""
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 错误消息
    @Published var errorMessage: String?
    
    /// 是否显示错误
    @Published var showError: Bool = false
    
    /// 是否发送成功
    @Published var isEmailSent: Bool = false
    
    /// 是否显示成功提示
    @Published var showSuccessAlert: Bool = false
    
    // MARK: - Computed Properties
    
    /// 邮箱验证错误
    var emailError: String? {
        guard !email.isEmpty else { return nil }
        if let error = validationService.validateEmail(email) {
            return error.message
        }
        return nil
    }
    
    /// 表单是否有效（可以提交）
    var isFormValid: Bool {
        return !email.isEmpty &&
               validationService.validateEmail(email) == nil
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
    
    /// 发送密码重置邮件
    func sendPasswordReset() async {
        // 验证邮箱
        if let error = validationService.validateForgotPassword(email: email) {
            errorMessage = error.message
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // 发送密码重置邮件
            try await authService.sendPasswordReset(to: email)
            
            // 发送成功
            isEmailSent = true
            showSuccessAlert = true
            isLoading = false
            
        } catch let error as AuthError {
            isLoading = false
            errorMessage = error.message
            showError = true
        } catch {
            isLoading = false
            errorMessage = "发送重置邮件失败，请稍后重试"
            showError = true
        }
    }
    
    /// 重置状态（用于重新尝试）
    func reset() {
        email = ""
        isEmailSent = false
        showSuccessAlert = false
        errorMessage = nil
        showError = false
    }
    
    /// 清除错误
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

