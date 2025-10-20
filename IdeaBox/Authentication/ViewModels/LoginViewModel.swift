import Foundation
import Combine

/// 登录页面 ViewModel
@MainActor
final class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 邮箱输入
    @Published var email: String = ""
    
    /// 密码输入
    @Published var password: String = ""
    
    /// 记住我
    @Published var rememberMe: Bool = false
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 错误消息
    @Published var errorMessage: String?
    
    /// 是否显示错误
    @Published var showError: Bool = false
    
    /// 登录成功（用于导航）
    @Published var isLoggedIn: Bool = false
    
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
               !password.isEmpty &&
               validationService.validateEmail(email) == nil
    }
    
    // MARK: - Services
    
    private let authService: AuthenticationServiceProtocol
    private let sessionManager: UserSessionManagerProtocol
    private let validationService: ValidationServiceProtocol
    
    // MARK: - Initialization
    
    init(
        authService: AuthenticationServiceProtocol = AuthenticationService(),
        sessionManager: UserSessionManagerProtocol = UserSessionManager(),
        validationService: ValidationServiceProtocol = ValidationService()
    ) {
        self.authService = authService
        self.sessionManager = sessionManager
        self.validationService = validationService
    }
    
    // MARK: - Actions
    
    /// 登录
    func signIn() async {
        // 验证输入
        let errors = validationService.validateLogin(email: email, password: password)
        if !errors.isEmpty {
            errorMessage = errors.first?.message
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // 执行登录
            let user = try await authService.signIn(
                email: email,
                password: password,
                rememberMe: rememberMe
            )
            
            // 获取访问令牌
            if let token = authService.getCurrentUser()?.id {
                // 创建并保存会话
                let session = try sessionManager.createSession(
                    for: user,
                    accessToken: token,
                    refreshToken: nil,
                    rememberMe: rememberMe
                )
                try sessionManager.saveSession(session)
            }
            
            // 登录成功
            isLoggedIn = true
            isLoading = false
            
            // 发送登录成功通知
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
            
        } catch let error as AuthError {
            isLoading = false
            errorMessage = error.message
            showError = true
        } catch {
            isLoading = false
            errorMessage = "登录失败，请稍后重试"
            showError = true
        }
    }
    
    /// 清除错误
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

