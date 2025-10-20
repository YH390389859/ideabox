import XCTest
import FirebaseAuth
@testable import IdeaBox

/// 邮箱认证集成测试
/// 测试完整的注册、登录、密码重置和会话流程
final class EmailAuthIntegrationTests: XCTestCase {
    
    var authService: AuthenticationService!
    var sessionManager: UserSessionManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        authService = AuthenticationService()
        sessionManager = UserSessionManager()
        
        // 清理会话
        try? sessionManager.clearSession()
        try? authService.signOut()
    }
    
    override func tearDownWithError() throws {
        try? sessionManager.clearSession()
        try? authService.signOut()
        authService = nil
        sessionManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - T018: 邮箱注册集成测试
    
    func testEmailSignUpFlow_CompleteWorkflow() async throws {
        // Given
        let email = "integration\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        // When: 注册新用户
        let user = try await authService.signUp(email: email, password: password)
        
        // Then: 验证用户信息
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.authMethod, .email)
        XCTAssertFalse(user.emailVerified)
        
        // When: 发送验证邮件
        try await authService.sendEmailVerification(to: user)
        
        // Then: 验证用户仍然登录
        XCTAssertTrue(authService.isUserSignedIn())
        
        // When: 创建会话
        let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
        let session = try sessionManager.createSession(
            for: user,
            accessToken: token,
            refreshToken: nil,
            rememberMe: false
        )
        
        // Then: 验证会话
        XCTAssertFalse(session.isExpired)
        XCTAssertEqual(session.userId, user.id)
        
        // Cleanup
        try await authService.deleteAccount()
    }
    
    // MARK: - T019: 邮箱登录集成测试
    
    func testEmailSignInFlow_CompleteWorkflow() async throws {
        // Given: 先注册一个用户
        let email = "signin\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        _ = try await authService.signUp(email: email, password: password)
        try authService.signOut()
        
        // When: 登录
        let user = try await authService.signIn(email: email, password: password, rememberMe: true)
        
        // Then: 验证登录成功
        XCTAssertEqual(user.email, email)
        XCTAssertTrue(authService.isUserSignedIn())
        
        // When: 创建会话（记住我 = 90天）
        let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
        let session = try sessionManager.createSession(
            for: user,
            accessToken: token,
            refreshToken: nil,
            rememberMe: true
        )
        
        // Then: 验证会话设置
        XCTAssertTrue(session.rememberMe)
        XCTAssertEqual(session.remainingDays, 90, accuracy: 1)
        
        // When: 保存会话
        try sessionManager.saveSession(session)
        
        // Then: 恢复会话成功
        let restoredSession = try sessionManager.restoreSession()
        XCTAssertNotNil(restoredSession)
        XCTAssertEqual(restoredSession?.userId, user.id)
        
        // Cleanup
        try await authService.deleteAccount()
    }
    
    // MARK: - T020: 密码重置集成测试
    
    func testPasswordResetFlow_CompleteWorkflow() async throws {
        // Given: 先注册一个用户
        let email = "reset\(UUID().uuidString)@example.com"
        let password = "OriginalPassword123"
        _ = try await authService.signUp(email: email, password: password)
        try authService.signOut()
        
        // When: 发送密码重置邮件
        try await authService.sendPasswordReset(to: email)
        
        // Then: 不会抛出错误即为成功（实际邮件发送由 Firebase 处理）
        // 注意：在真实测试中，需要检查邮件是否收到
        
        // When: 使用原密码登录（应该仍然有效，因为还没有重置）
        let user = try await authService.signIn(email: email, password: password, rememberMe: false)
        
        // Then: 验证登录成功
        XCTAssertEqual(user.email, email)
        
        // Cleanup
        try await authService.deleteAccount()
    }
    
    // MARK: - T021: 会话持久化集成测试
    
    func testSessionPersistenceFlow_CompleteWorkflow() async throws {
        // Given: 注册并登录
        let email = "session\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        let user = try await authService.signUp(email: email, password: password)
        
        // When: 创建并保存会话
        let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
        let session = try sessionManager.createSession(
            for: user,
            accessToken: token,
            refreshToken: nil,
            rememberMe: false
        )
        try sessionManager.saveSession(session)
        
        // Then: 恢复会话成功
        let restoredSession = try sessionManager.restoreSession()
        XCTAssertNotNil(restoredSession)
        XCTAssertEqual(restoredSession?.id, session.id)
        XCTAssertEqual(restoredSession?.accessToken, session.accessToken)
        
        // When: 更新会话活跃时间
        let touchedSession = sessionManager.touchSession(session)
        try sessionManager.saveSession(touchedSession)
        
        // Then: 恢复的会话有更新的访问时间
        let finalSession = try sessionManager.restoreSession()
        XCTAssertNotNil(finalSession)
        XCTAssertGreaterThan(finalSession!.lastAccessedAt, session.lastAccessedAt)
        
        // When: 清除会话
        try sessionManager.clearSession()
        
        // Then: 无法恢复会话
        let clearedSession = try sessionManager.restoreSession()
        XCTAssertNil(clearedSession)
        
        // Cleanup
        try await authService.deleteAccount()
    }
    
    // MARK: - Complete End-to-End Flow
    
    func testCompleteAuthFlow_FromSignUpToSignOut() async throws {
        // Given
        let email = "e2e\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        // Step 1: 注册
        let user = try await authService.signUp(email: email, password: password)
        XCTAssertTrue(authService.isUserSignedIn())
        
        // Step 2: 创建会话
        let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
        let session = try sessionManager.createSession(
            for: user,
            accessToken: token,
            refreshToken: nil,
            rememberMe: false
        )
        try sessionManager.saveSession(session)
        
        // Step 3: 登出
        try authService.signOut()
        XCTAssertFalse(authService.isUserSignedIn())
        
        // Step 4: 重新登录
        let user2 = try await authService.signIn(email: email, password: password, rememberMe: false)
        XCTAssertEqual(user2.email, email)
        XCTAssertTrue(authService.isUserSignedIn())
        
        // Step 5: 恢复会话
        let restoredSession = try sessionManager.restoreSession()
        XCTAssertNotNil(restoredSession)
        
        // Step 6: 清除会话并登出
        try sessionManager.clearSession()
        try authService.signOut()
        
        // Then: 完全清空
        XCTAssertFalse(authService.isUserSignedIn())
        let finalSession = try sessionManager.restoreSession()
        XCTAssertNil(finalSession)
        
        // Cleanup
        _ = try await authService.signIn(email: email, password: password, rememberMe: false)
        try await authService.deleteAccount()
    }
}

