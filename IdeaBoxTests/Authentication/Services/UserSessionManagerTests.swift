import XCTest
@testable import IdeaBox

/// UserSessionManager 单元测试
/// 测试会话的创建、持久化、恢复、刷新和过期检测
final class UserSessionManagerTests: XCTestCase {
    
    var sut: UserSessionManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = UserSessionManager()
        // 清理之前的会话
        try? sut.clearSession()
    }
    
    override func tearDownWithError() throws {
        // 确保清理测试会话
        try? sut.clearSession()
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Session Creation Tests
    
    func testCreateSession_WithValidData_CreatesSession() throws {
        // Given
        let user = createTestUser()
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        
        // When
        let session = try sut.createSession(
            for: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
            rememberMe: false
        )
        
        // Then
        XCTAssertEqual(session.userId, user.id)
        XCTAssertEqual(session.accessToken, accessToken)
        XCTAssertEqual(session.refreshToken, refreshToken)
        XCTAssertFalse(session.rememberMe)
        XCTAssertFalse(session.isExpired)
    }
    
    func testCreateSession_WithRememberMeTrue_Creates90DaySession() throws {
        // Given
        let user = createTestUser()
        let accessToken = "test_access_token"
        
        // When
        let session = try sut.createSession(
            for: user,
            accessToken: accessToken,
            refreshToken: nil,
            rememberMe: true
        )
        
        // Then
        XCTAssertTrue(session.rememberMe)
        
        // 检查过期时间是否约为 90 天
        let expectedExpiry = Date().addingTimeInterval(90 * 24 * 60 * 60)
        let timeDifference = abs(session.expiresAt.timeIntervalSince(expectedExpiry))
        XCTAssertLessThan(timeDifference, 60) // 允许 60 秒误差
    }
    
    func testCreateSession_WithRememberMeFalse_Creates30DaySession() throws {
        // Given
        let user = createTestUser()
        let accessToken = "test_access_token"
        
        // When
        let session = try sut.createSession(
            for: user,
            accessToken: accessToken,
            refreshToken: nil,
            rememberMe: false
        )
        
        // Then
        XCTAssertFalse(session.rememberMe)
        
        // 检查过期时间是否约为 30 天
        let expectedExpiry = Date().addingTimeInterval(30 * 24 * 60 * 60)
        let timeDifference = abs(session.expiresAt.timeIntervalSince(expectedExpiry))
        XCTAssertLessThan(timeDifference, 60) // 允许 60 秒误差
    }
    
    // MARK: - Session Persistence Tests
    
    func testSaveAndRestoreSession_SavesAndRestoresCorrectly() throws {
        // Given
        let user = createTestUser()
        let accessToken = "test_access_token_save"
        let session = try sut.createSession(
            for: user,
            accessToken: accessToken,
            refreshToken: nil,
            rememberMe: false
        )
        
        // When
        try sut.saveSession(session)
        let restoredSession = try sut.restoreSession()
        
        // Then
        XCTAssertNotNil(restoredSession)
        XCTAssertEqual(restoredSession?.id, session.id)
        XCTAssertEqual(restoredSession?.userId, session.userId)
        XCTAssertEqual(restoredSession?.accessToken, session.accessToken)
    }
    
    func testRestoreSession_WhenNoSessionSaved_ReturnsNil() throws {
        // Given
        try sut.clearSession()
        
        // When
        let session = try sut.restoreSession()
        
        // Then
        XCTAssertNil(session)
    }
    
    func testClearSession_RemovesSession() throws {
        // Given
        let user = createTestUser()
        let session = try sut.createSession(
            for: user,
            accessToken: "test_token",
            refreshToken: nil,
            rememberMe: false
        )
        try sut.saveSession(session)
        
        // When
        try sut.clearSession()
        let restoredSession = try sut.restoreSession()
        
        // Then
        XCTAssertNil(restoredSession)
    }
    
    // MARK: - Session Validation Tests
    
    func testIsSessionValid_WithValidSession_ReturnsTrue() throws {
        // Given
        let user = createTestUser()
        let session = try sut.createSession(
            for: user,
            accessToken: "test_token",
            refreshToken: nil,
            rememberMe: false
        )
        
        // When
        let isValid = sut.isSessionValid(session)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testIsSessionValid_WithExpiredSession_ReturnsFalse() throws {
        // Given
        let user = createTestUser()
        var session = try sut.createSession(
            for: user,
            accessToken: "test_token",
            refreshToken: nil,
            rememberMe: false
        )
        
        // 手动设置为已过期
        let pastDate = Date().addingTimeInterval(-60 * 60) // 1 小时前
        session = UserSession(
            id: session.id,
            userId: session.userId,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            createdAt: session.createdAt,
            expiresAt: pastDate,
            lastAccessedAt: session.lastAccessedAt,
            rememberMe: session.rememberMe,
            deviceId: session.deviceId,
            deviceName: session.deviceName
        )
        
        // When
        let isValid = sut.isSessionValid(session)
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testIsSessionExpiringSoon_WithSessionExpiringSoon_ReturnsTrue() throws {
        // Given
        let user = createTestUser()
        var session = try sut.createSession(
            for: user,
            accessToken: "test_token",
            refreshToken: nil,
            rememberMe: false
        )
        
        // 设置为 12 小时后过期
        let soonDate = Date().addingTimeInterval(12 * 60 * 60)
        session = UserSession(
            id: session.id,
            userId: session.userId,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            createdAt: session.createdAt,
            expiresAt: soonDate,
            lastAccessedAt: session.lastAccessedAt,
            rememberMe: session.rememberMe,
            deviceId: session.deviceId,
            deviceName: session.deviceName
        )
        
        // When
        let isExpiringSoon = sut.isSessionExpiringSoon(session)
        
        // Then
        XCTAssertTrue(isExpiringSoon)
    }
    
    func testIsSessionExpiringSoon_WithFreshSession_ReturnsFalse() throws {
        // Given
        let user = createTestUser()
        let session = try sut.createSession(
            for: user,
            accessToken: "test_token",
            refreshToken: nil,
            rememberMe: false
        )
        
        // When
        let isExpiringSoon = sut.isSessionExpiringSoon(session)
        
        // Then
        XCTAssertFalse(isExpiringSoon)
    }
    
    // MARK: - Session Activity Tests
    
    func testTouchSession_UpdatesLastAccessedTime() throws {
        // Given
        let user = createTestUser()
        let session = try sut.createSession(
            for: user,
            accessToken: "test_token",
            refreshToken: nil,
            rememberMe: false
        )
        
        let originalLastAccessedAt = session.lastAccessedAt
        
        // 等待一小段时间
        Thread.sleep(forTimeInterval: 0.1)
        
        // When
        let updatedSession = sut.touchSession(session)
        
        // Then
        XCTAssertGreaterThan(updatedSession.lastAccessedAt, originalLastAccessedAt)
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser() -> User {
        return User(
            id: UUID().uuidString,
            email: "test@example.com",
            displayName: "Test User",
            photoURL: nil,
            createdAt: Date(),
            lastLoginAt: Date(),
            emailVerified: false,
            authMethod: .email,
            rememberMe: false,
            theme: .system,
            language: "zh"
        )
    }
}

