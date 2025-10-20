import XCTest
import FirebaseAuth
@testable import IdeaBox

/// AuthenticationService 单元测试
/// 测试用户注册、登录、登出等核心认证功能
final class AuthenticationServiceTests: XCTestCase {
    
    var sut: AuthenticationService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = AuthenticationService()
    }
    
    override func tearDownWithError() throws {
        // 确保每个测试后都登出
        try? sut.signOut()
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUp_WithValidCredentials_CreatesNewUser() async throws {
        // Given
        let email = "test\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        // When
        let user = try await sut.signUp(email: email, password: password)
        
        // Then
        XCTAssertEqual(user.email, email)
        XCTAssertFalse(user.emailVerified)
        XCTAssertEqual(user.authMethod, .email)
        
        // Cleanup
        try await sut.deleteAccount()
    }
    
    func testSignUp_WithExistingEmail_ThrowsEmailAlreadyInUseError() async throws {
        // Given
        let email = "existing\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        // 先创建一个用户
        _ = try await sut.signUp(email: email, password: password)
        try sut.signOut()
        
        // When & Then
        do {
            _ = try await sut.signUp(email: email, password: password)
            XCTFail("Expected emailAlreadyInUse error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .emailAlreadyInUse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Cleanup
        _ = try await sut.signIn(email: email, password: password, rememberMe: false)
        try await sut.deleteAccount()
    }
    
    func testSignUp_WithWeakPassword_ThrowsInvalidPasswordError() async throws {
        // Given
        let email = "test\(UUID().uuidString)@example.com"
        let weakPassword = "weak"
        
        // When & Then
        do {
            _ = try await sut.signUp(email: email, password: weakPassword)
            XCTFail("Expected invalidPassword error")
        } catch let error as AuthError {
            if case .invalidPassword = error {
                // Success
            } else {
                XCTFail("Expected invalidPassword error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Sign In Tests
    
    func testSignIn_WithValidCredentials_ReturnsUser() async throws {
        // Given
        let email = "signin\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        // 先注册用户
        _ = try await sut.signUp(email: email, password: password)
        try sut.signOut()
        
        // When
        let user = try await sut.signIn(email: email, password: password, rememberMe: false)
        
        // Then
        XCTAssertEqual(user.email, email)
        XCTAssertTrue(sut.isUserSignedIn())
        
        // Cleanup
        try await sut.deleteAccount()
    }
    
    func testSignIn_WithWrongPassword_ThrowsWrongPasswordError() async throws {
        // Given
        let email = "wrongpass\(UUID().uuidString)@example.com"
        let password = "CorrectPassword123"
        let wrongPassword = "WrongPassword456"
        
        // 先注册用户
        _ = try await sut.signUp(email: email, password: password)
        try sut.signOut()
        
        // When & Then
        do {
            _ = try await sut.signIn(email: email, password: wrongPassword, rememberMe: false)
            XCTFail("Expected wrongPassword error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .wrongPassword)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Cleanup
        _ = try await sut.signIn(email: email, password: password, rememberMe: false)
        try await sut.deleteAccount()
    }
    
    func testSignIn_WithNonExistentUser_ThrowsUserNotFoundError() async throws {
        // Given
        let email = "nonexistent\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        // When & Then
        do {
            _ = try await sut.signIn(email: email, password: password, rememberMe: false)
            XCTFail("Expected userNotFound error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .userNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Get Current User Tests
    
    func testGetCurrentUser_WhenSignedIn_ReturnsUser() async throws {
        // Given
        let email = "current\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        _ = try await sut.signUp(email: email, password: password)
        
        // When
        let currentUser = sut.getCurrentUser()
        
        // Then
        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.email, email)
        
        // Cleanup
        try await sut.deleteAccount()
    }
    
    func testGetCurrentUser_WhenNotSignedIn_ReturnsNil() throws {
        // Given
        try sut.signOut()
        
        // When
        let currentUser = sut.getCurrentUser()
        
        // Then
        XCTAssertNil(currentUser)
    }
    
    // MARK: - Is User Signed In Tests
    
    func testIsUserSignedIn_WhenSignedIn_ReturnsTrue() async throws {
        // Given
        let email = "signedin\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        _ = try await sut.signUp(email: email, password: password)
        
        // When
        let isSignedIn = sut.isUserSignedIn()
        
        // Then
        XCTAssertTrue(isSignedIn)
        
        // Cleanup
        try await sut.deleteAccount()
    }
    
    func testIsUserSignedIn_WhenNotSignedIn_ReturnsFalse() throws {
        // Given
        try sut.signOut()
        
        // When
        let isSignedIn = sut.isUserSignedIn()
        
        // Then
        XCTAssertFalse(isSignedIn)
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_ClearsCurrentUser() async throws {
        // Given
        let email = "signout\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        let user = try await sut.signUp(email: email, password: password)
        XCTAssertTrue(sut.isUserSignedIn())
        
        // When
        try sut.signOut()
        
        // Then
        XCTAssertFalse(sut.isUserSignedIn())
        XCTAssertNil(sut.getCurrentUser())
        
        // Cleanup - 需要重新登录才能删除
        _ = try await sut.signIn(email: email, password: password, rememberMe: false)
        try await sut.deleteAccount()
    }
    
    // MARK: - Email Verification Tests
    
    func testSendEmailVerification_SendsEmail() async throws {
        // Given
        let email = "verify\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        let user = try await sut.signUp(email: email, password: password)
        
        // When & Then - 不会抛出错误即为成功
        try await sut.sendEmailVerification(to: user)
        
        // Cleanup
        try await sut.deleteAccount()
    }
    
    // MARK: - Password Reset Tests
    
    func testSendPasswordReset_WithValidEmail_SendsEmail() async throws {
        // Given
        let email = "reset\(UUID().uuidString)@example.com"
        let password = "TestPassword123"
        
        // 先创建用户
        _ = try await sut.signUp(email: email, password: password)
        try sut.signOut()
        
        // When & Then - 不会抛出错误即为成功
        try await sut.sendPasswordReset(to: email)
        
        // Cleanup
        _ = try await sut.signIn(email: email, password: password, rememberMe: false)
        try await sut.deleteAccount()
    }
    
    func testSendPasswordReset_WithNonExistentEmail_ThrowsUserNotFoundError() async throws {
        // Given
        let email = "nonexistent\(UUID().uuidString)@example.com"
        
        // When & Then
        do {
            try await sut.sendPasswordReset(to: email)
            XCTFail("Expected userNotFound error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .userNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

