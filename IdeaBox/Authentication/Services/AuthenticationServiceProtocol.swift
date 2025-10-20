import Foundation
import FirebaseAuth

/// 认证服务协议
/// 负责用户注册、登录、登出、密码重置等核心认证功能
protocol AuthenticationServiceProtocol {
    // MARK: - User Registration
    
    /// 使用邮箱和密码注册新用户
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - password: 密码
    /// - Returns: 新注册的用户
    /// - Throws: AuthError（邮箱已存在、密码格式错误等）
    func signUp(email: String, password: String) async throws -> User
    
    /// 发送邮箱验证邮件
    /// - Parameter user: 需要验证邮箱的用户
    /// - Throws: AuthError（网络错误等）
    func sendEmailVerification(to user: User) async throws
    
    // MARK: - User Login
    
    /// 使用邮箱和密码登录
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - password: 密码
    ///   - rememberMe: 是否记住登录状态（90天 vs 30天）
    /// - Returns: 登录的用户
    /// - Throws: AuthError（用户不存在、密码错误等）
    func signIn(email: String, password: String, rememberMe: Bool) async throws -> User
    
    /// 获取当前登录的用户
    /// - Returns: 当前用户（如果未登录返回 nil）
    func getCurrentUser() -> User?
    
    /// 检查用户是否已登录
    /// - Returns: 是否已登录
    func isUserSignedIn() -> Bool
    
    // MARK: - User Logout
    
    /// 登出当前用户
    /// - Throws: AuthError（会话错误等）
    func signOut() throws
    
    // MARK: - Password Reset
    
    /// 发送密码重置邮件
    /// - Parameter email: 邮箱地址
    /// - Throws: AuthError（用户不存在、网络错误等）
    func sendPasswordReset(to email: String) async throws
    
    /// 更改密码（用户已登录状态）
    /// - Parameters:
    ///   - currentPassword: 当前密码
    ///   - newPassword: 新密码
    /// - Throws: AuthError（当前密码错误、新密码格式错误等）
    func changePassword(currentPassword: String, newPassword: String) async throws
    
    // MARK: - Account Management
    
    /// 删除当前用户账号
    /// - Throws: AuthError（需要重新认证等）
    func deleteAccount() async throws
}

