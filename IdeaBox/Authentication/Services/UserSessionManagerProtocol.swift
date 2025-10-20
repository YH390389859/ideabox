import Foundation

/// 用户会话管理服务协议
/// 负责会话的创建、持久化、恢复、刷新和过期检测
protocol UserSessionManagerProtocol {
    // MARK: - Session Creation
    
    /// 为用户创建新会话
    /// - Parameters:
    ///   - user: 用户对象
    ///   - accessToken: 访问令牌（Firebase ID Token）
    ///   - refreshToken: 刷新令牌（可选）
    ///   - rememberMe: 是否"记住我"（90天 vs 30天）
    /// - Returns: 新创建的会话
    /// - Throws: AuthError（Keychain 保存失败等）
    func createSession(
        for user: User,
        accessToken: String,
        refreshToken: String?,
        rememberMe: Bool
    ) throws -> UserSession
    
    // MARK: - Session Persistence
    
    /// 保存会话到 Keychain
    /// - Parameter session: 要保存的会话
    /// - Throws: AuthError（Keychain 保存失败）
    func saveSession(_ session: UserSession) throws
    
    /// 从 Keychain 恢复会话
    /// - Returns: 已保存的会话（如果不存在返回 nil）
    /// - Throws: AuthError（Keychain 读取失败）
    func restoreSession() throws -> UserSession?
    
    /// 清除会话（从 Keychain 删除）
    /// - Throws: AuthError（Keychain 删除失败）
    func clearSession() throws
    
    // MARK: - Session Validation
    
    /// 检查会话是否有效
    /// - Parameter session: 要检查的会话
    /// - Returns: 会话是否有效（未过期）
    func isSessionValid(_ session: UserSession) -> Bool
    
    /// 检查会话是否即将过期
    /// - Parameter session: 要检查的会话
    /// - Returns: 会话是否即将过期（剩余不到1天）
    func isSessionExpiringSoon(_ session: UserSession) -> Bool
    
    // MARK: - Session Refresh
    
    /// 刷新访问令牌
    /// - Parameter session: 要刷新的会话
    /// - Returns: 刷新后的会话
    /// - Throws: AuthError（刷新失败、网络错误等）
    func refreshSession(_ session: UserSession) async throws -> UserSession
    
    // MARK: - Session Activity
    
    /// 更新会话最后访问时间
    /// - Parameter session: 要更新的会话
    /// - Returns: 更新后的会话
    func touchSession(_ session: UserSession) -> UserSession
}

