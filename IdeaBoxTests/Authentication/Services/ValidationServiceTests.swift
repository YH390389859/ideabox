import XCTest
@testable import IdeaBox

/// ValidationService 单元测试
/// 测试输入验证逻辑（邮箱、密码）
final class ValidationServiceTests: XCTestCase {
    
    var sut: ValidationService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = ValidationService()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Email Validation Tests
    
    func testValidateEmail_WithValidEmail_ReturnsNil() {
        // Given
        let validEmails = [
            "user@example.com",
            "test.user@domain.co.uk",
            "name+tag@company.org",
            "123@test.com",
            "a@b.c"
        ]
        
        // When & Then
        for email in validEmails {
            let error = sut.validateEmail(email)
            XCTAssertNil(error, "Expected \(email) to be valid")
        }
    }
    
    func testValidateEmail_WithEmptyEmail_ReturnsEmptyEmailError() {
        // Given
        let emptyEmails = ["", "   ", "\n", "\t"]
        
        // When & Then
        for email in emptyEmails {
            let error = sut.validateEmail(email)
            XCTAssertEqual(error, .emptyEmail)
        }
    }
    
    func testValidateEmail_WithInvalidFormat_ReturnsInvalidFormatError() {
        // Given
        let invalidEmails = [
            "notanemail",
            "missing@domain",
            "@nodomain.com",
            "no@domain@extra.com",
            "spaces in@email.com",
            "email@",
            "email@.com"
        ]
        
        // When & Then
        for email in invalidEmails {
            let error = sut.validateEmail(email)
            XCTAssertEqual(error, .invalidEmailFormat, "Expected \(email) to be invalid")
        }
    }
    
    func testValidateEmail_WithTooLongEmail_ReturnsEmailTooLongError() {
        // Given
        let longEmail = String(repeating: "a", count: 300) + "@example.com"
        
        // When
        let error = sut.validateEmail(longEmail)
        
        // Then
        XCTAssertEqual(error, .emailTooLong)
    }
    
    // MARK: - Password Validation Tests
    
    func testValidatePassword_WithValidPassword_ReturnsNil() {
        // Given
        let validPasswords = [
            "Password123",
            "MySecureP@ss1",
            "Aa123456",
            "Test1234",
            "StrongP@ssw0rd"
        ]
        
        // When & Then
        for password in validPasswords {
            let error = sut.validatePassword(password)
            XCTAssertNil(error, "Expected \(password) to be valid")
        }
    }
    
    func testValidatePassword_WithEmptyPassword_ReturnsEmptyPasswordError() {
        // Given
        let password = ""
        
        // When
        let error = sut.validatePassword(password)
        
        // Then
        XCTAssertEqual(error, .emptyPassword)
    }
    
    func testValidatePassword_WithTooShortPassword_ReturnsPasswordTooShortError() {
        // Given
        let shortPasswords = ["Pass1", "Aa1", "Test12"]
        
        // When & Then
        for password in shortPasswords {
            let error = sut.validatePassword(password)
            XCTAssertEqual(error, .passwordTooShort, "Expected \(password) to be too short")
        }
    }
    
    func testValidatePassword_WithTooLongPassword_ReturnsPasswordTooLongError() {
        // Given
        let longPassword = String(repeating: "Password1", count: 15) // 135 chars
        
        // When
        let error = sut.validatePassword(longPassword)
        
        // Then
        XCTAssertEqual(error, .passwordTooLong)
    }
    
    func testValidatePassword_WithMissingUppercase_ReturnsPasswordMissingUppercaseError() {
        // Given
        let password = "password123"
        
        // When
        let error = sut.validatePassword(password)
        
        // Then
        XCTAssertEqual(error, .passwordMissingUppercase)
    }
    
    func testValidatePassword_WithMissingLowercase_ReturnsPasswordMissingLowercaseError() {
        // Given
        let password = "PASSWORD123"
        
        // When
        let error = sut.validatePassword(password)
        
        // Then
        XCTAssertEqual(error, .passwordMissingLowercase)
    }
    
    func testValidatePassword_WithMissingDigit_ReturnsPasswordMissingDigitError() {
        // Given
        let password = "PasswordOnly"
        
        // When
        let error = sut.validatePassword(password)
        
        // Then
        XCTAssertEqual(error, .passwordMissingDigit)
    }
    
    // MARK: - Password Strength Tests
    
    func testEvaluatePasswordStrength_WithWeakPassword_ReturnsVeryWeak() {
        // Given
        let weakPasswords = ["Pass1", "abc123", "123456"]
        
        // When & Then
        for password in weakPasswords {
            let strength = sut.evaluatePasswordStrength(password)
            XCTAssertTrue(strength == .veryWeak || strength == .weak, "Expected \(password) to be weak")
        }
    }
    
    func testEvaluatePasswordStrength_WithMediumPassword_ReturnsMedium() {
        // Given
        let password = "Password123"
        
        // When
        let strength = sut.evaluatePasswordStrength(password)
        
        // Then
        XCTAssertEqual(strength, .medium)
    }
    
    func testEvaluatePasswordStrength_WithStrongPassword_ReturnsStrong() {
        // Given
        let password = "MyStr0ngP@ssw0rd!"
        
        // When
        let strength = sut.evaluatePasswordStrength(password)
        
        // Then
        XCTAssertTrue(strength >= .strong, "Expected password to be strong or very strong")
    }
    
    // MARK: - Password Match Tests
    
    func testValidatePasswordMatch_WithMatchingPasswords_ReturnsNil() {
        // Given
        let password = "Password123"
        let confirmation = "Password123"
        
        // When
        let error = sut.validatePasswordMatch(password, confirmation)
        
        // Then
        XCTAssertNil(error)
    }
    
    func testValidatePasswordMatch_WithDifferentPasswords_ReturnsPasswordMismatchError() {
        // Given
        let password = "Password123"
        let confirmation = "DifferentPassword456"
        
        // When
        let error = sut.validatePasswordMatch(password, confirmation)
        
        // Then
        XCTAssertEqual(error, .passwordMismatch)
    }
    
    // MARK: - Combined Validation Tests
    
    func testValidateSignUp_WithValidInputs_ReturnsEmptyArray() {
        // Given
        let email = "user@example.com"
        let password = "Password123"
        let confirmation = "Password123"
        
        // When
        let errors = sut.validateSignUp(email: email, password: password, confirmation: confirmation)
        
        // Then
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testValidateSignUp_WithMultipleErrors_ReturnsAllErrors() {
        // Given
        let email = "invalidemail"
        let password = "weak"
        let confirmation = "different"
        
        // When
        let errors = sut.validateSignUp(email: email, password: password, confirmation: confirmation)
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains(.invalidEmailFormat))
        XCTAssertTrue(errors.contains(.passwordTooShort))
    }
    
    func testValidateLogin_WithValidInputs_ReturnsEmptyArray() {
        // Given
        let email = "user@example.com"
        let password = "anypassword"
        
        // When
        let errors = sut.validateLogin(email: email, password: password)
        
        // Then
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testValidateLogin_WithInvalidEmail_ReturnsEmailError() {
        // Given
        let email = "invalidemail"
        let password = "anypassword"
        
        // When
        let errors = sut.validateLogin(email: email, password: password)
        
        // Then
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors.first, .invalidEmailFormat)
    }
    
    func testValidateForgotPassword_WithValidEmail_ReturnsNil() {
        // Given
        let email = "user@example.com"
        
        // When
        let error = sut.validateForgotPassword(email: email)
        
        // Then
        XCTAssertNil(error)
    }
}

