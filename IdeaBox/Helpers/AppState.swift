import Foundation
import SwiftUI

/// 应用全局状态管理
@MainActor
class AppState: ObservableObject {
    /// 当前用户
    @Published var currentUser: User?
    
    /// 是否已登录
    @Published var isAuthenticated: Bool = false
    
    /// 是否正在检查登录状态
    @Published var isCheckingAuth: Bool = true
    
    private let authService: AuthenticationServiceProtocol
    private let sessionManager: UserSessionManagerProtocol
    
    init(
        authService: AuthenticationServiceProtocol = AuthenticationService(),
        sessionManager: UserSessionManagerProtocol = UserSessionManager()
    ) {
        self.authService = authService
        self.sessionManager = sessionManager
    }
    
    /// 检查登录状态
    func checkAuthStatus() {
        isCheckingAuth = true
        
        // 尝试从 Keychain 恢复会话
        if let session = try? sessionManager.restoreSession(),
           sessionManager.isSessionValid(session) {
            // 会话有效，获取当前用户
            if let user = authService.getCurrentUser() {
                currentUser = user
                isAuthenticated = true
            } else {
                // 会话有效但 Firebase 未登录，清除会话
                try? sessionManager.clearSession()
                isAuthenticated = false
            }
        } else {
            // 无有效会话
            try? sessionManager.clearSession()
            isAuthenticated = false
        }
        
        isCheckingAuth = false
    }
    
    /// 登出
    func signOut() {
        do {
            try authService.signOut()
            try sessionManager.clearSession()
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("登出失败: \(error)")
        }
    }
}

