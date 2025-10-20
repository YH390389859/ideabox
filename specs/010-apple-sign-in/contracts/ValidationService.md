# Contract: ValidationService

**Service**: Input Validation  
**Purpose**: Validate user inputs for email, password, and other authentication fields  
**Date**: 2025-10-20  
**Status**: Defined ✅

---

## Overview

`ValidationService` 提供邮箱、密码等输入字段的验证功能，确保用户输入符合格式要求和安全标准。支持实时验证和提交验证两种模式。

---

## Protocol Definition

```swift
import Foundation

/// Input validation service protocol
protocol ValidationServiceProtocol {
    
    // MARK: - Email Validation
    
    /// Validate email address format
    /// - Parameter email: Email address to validate
    /// - Returns: Success if valid, failure with error if invalid
    func validateEmail(_ email: String) -> Result<Void, ValidationError>
    
    /// Check if email is in valid format (synchronous)
    /// - Parameter email: Email address to check
    /// - Returns: true if format is valid
    func isValidEmail(_ email: String) -> Bool
    
    // MARK: - Password Validation
    
    /// Validate password meets security requirements
    /// - Parameter password: Password to validate
    /// - Returns: Success if valid, failure with error if invalid
    func validatePassword(_ password: String) -> Result<Void, ValidationError>
    
    /// Calculate password strength
    /// - Parameter password: Password to analyze
    /// - Returns: Password strength rating (weak, medium, strong)
    func calculatePasswordStrength(_ password: String) -> PasswordStrength
    
    /// Check if password is a common weak password
    /// - Parameter password: Password to check
    /// - Returns: true if password is in common password list
    func isCommonPassword(_ password: String) -> Bool
    
    // MARK: - Field Validation
    
    /// Validate a field is not empty
    /// - Parameters:
    ///   - value: Field value to check
    ///   - fieldName: Name of the field (for error message)
    /// - Returns: Success if not empty, failure if empty
    func validateNotEmpty(_ value: String, fieldName: String) -> Result<Void, ValidationError>
    
    // MARK: - Batch Validation
    
    /// Validate multiple fields at once for sign up form
    /// - Parameters:
    ///   - email: Email address
    ///   - password: Password
    ///   - confirmPassword: Password confirmation
    /// - Returns: Array of validation errors (empty if all valid)
    func validateSignUpForm(email: String, password: String, confirmPassword: String) -> [ValidationError]
    
    /// Validate multiple fields at once for sign in form
    /// - Parameters:
    ///   - email: Email address
    ///   - password: Password
    /// - Returns: Array of validation errors (empty if all valid)
    func validateSignInForm(email: String, password: String) -> [ValidationError]
}
```

---

## Method Specifications

### validateEmail(_:)

**Purpose**: Validate email address format according to RFC 5322 (simplified)

**Preconditions**: None

**Postconditions**:
- Returns `.success(())` if email format is valid
- Returns `.failure(ValidationError)` with specific error if invalid

**Validation Rules**:
1. Must not be empty
2. Must contain exactly one `@` symbol
3. Must have text before and after `@`
4. Must have at least one `.` in domain part
5. Domain must be at least 2 characters after final `.`
6. Allowed characters: `A-Za-z0-9._%+-`

**Error Cases**:
| Error | Condition | Example |
|-------|-----------|---------|
| `.emptyField` | Email is empty or whitespace | `""` |
| `.invalidEmailFormat` | Email format is invalid | `"notanemail"` |

**Example**:
```swift
switch validationService.validateEmail("user@example.com") {
case .success:
    // Email is valid
case .failure(let error):
    // Show error: error.errorDescription
}
```

**Test Cases**:
```swift
// Valid emails
✅ "user@example.com"
✅ "test.user@example.co.uk"
✅ "user+tag@example.com"
✅ "123@example.com"

// Invalid emails
❌ ""
❌ "notanemail"
❌ "@example.com"
❌ "user@"
❌ "user@@example.com"
❌ "user@example"
❌ "user@.com"
```

---

### isValidEmail(_:)

**Purpose**: Quick boolean check for email format validity

**Behavior**:
- Returns `true` if email format is valid
- Returns `false` otherwise
- Convenience method wrapping `validateEmail()`

**Example**:
```swift
if validationService.isValidEmail("user@example.com") {
    // Enable submit button
}
```

---

### validatePassword(_:)

**Purpose**: Validate password meets security requirements

**Preconditions**: None

**Postconditions**:
- Returns `.success(())` if password meets all requirements
- Returns `.failure(ValidationError)` with specific error if invalid

**Validation Rules** (following NIST SP 800-63B):
1. Minimum 8 characters
2. Must contain at least one letter (A-Z or a-z)
3. Must contain at least one number (0-9)
4. Must not be in common password list (top 10,000)
5. No maximum length (within reason, e.g., 128 chars)
6. Special characters NOT required (NIST recommendation)

**Error Cases**:
| Error | Condition | Example |
|-------|-----------|---------|
| `.emptyField` | Password is empty | `""` |
| `.passwordTooShort` | Less than 8 characters | `"Pass1"` |
| `.passwordNoLetters` | No letters present | `"12345678"` |
| `.passwordNoNumbers` | No numbers present | `"password"` |
| `.commonPassword` | In common password list | `"password123"` |

**Example**:
```swift
switch validationService.validatePassword("SecurePass123") {
case .success:
    // Password is secure
case .failure(let error):
    // Show error: error.errorDescription
}
```

**Test Cases**:
```swift
// Valid passwords
✅ "SecurePass123"
✅ "MyP@ssw0rd"
✅ "LongAndSecurePassword2024"

// Invalid passwords
❌ ""                  // Empty
❌ "short1"            // Too short
❌ "12345678"          // No letters
❌ "password"          // No numbers
❌ "password123"       // Common password
```

---

### calculatePasswordStrength(_:)

**Purpose**: Analyze password and return strength rating

**Preconditions**: None

**Postconditions**: Returns `PasswordStrength` enum (weak, medium, strong)

**Strength Calculation**:

```
Base score = 0

Length bonus:
+ 1 point if >= 8 characters
+ 1 point if >= 12 characters
+ 1 point if >= 16 characters

Character variety bonus:
+ 1 point if contains uppercase
+ 1 point if contains lowercase
+ 1 point if contains numbers
+ 1 point if contains special characters

Common password penalty:
- 3 points if in common password list

Final rating:
0-2 points = Weak
3-4 points = Medium
5+ points = Strong
```

**Example**:
```swift
let strength = validationService.calculatePasswordStrength("SecurePass123")
// Returns: .strong

switch strength {
case .weak:
    // Show red indicator
case .medium:
    // Show orange indicator
case .strong:
    // Show green indicator
}
```

**Test Cases**:
```swift
"Pass1"              → .weak
"password123"        → .weak (common)
"SecurePass123"      → .medium
"MyP@ssw0rd2024!"    → .strong
"SuperSecure123!@#"  → .strong
```

---

### isCommonPassword(_:)

**Purpose**: Check if password exists in list of commonly used weak passwords

**Preconditions**: None

**Postconditions**:
- Returns `true` if password is in common list (case-insensitive)
- Returns `false` otherwise

**Common Password List**:
- Top 10,000 most common passwords
- Includes: "password", "123456", "qwerty", etc.
- Case-insensitive comparison

**Example**:
```swift
if validationService.isCommonPassword("password123") {
    // Warn user: "This password is too common"
}
```

---

### validateNotEmpty(_:fieldName:)

**Purpose**: Validate that a field has non-empty content

**Preconditions**: None

**Postconditions**:
- Returns `.success(())` if value is not empty after trimming whitespace
- Returns `.failure(.emptyField(fieldName))` if empty

**Example**:
```swift
switch validationService.validateNotEmpty("John", fieldName: "姓名") {
case .success:
    // Field has value
case .failure(let error):
    // Show: "姓名不能为空"
}
```

---

### validateSignUpForm(email:password:confirmPassword:)

**Purpose**: Validate all fields in sign-up form at once

**Preconditions**: None

**Postconditions**:
- Returns empty array if all fields valid
- Returns array of `ValidationError` for all invalid fields

**Validation Checks**:
1. Email format validation
2. Password strength validation
3. Password confirmation match
4. All fields non-empty

**Example**:
```swift
let errors = validationService.validateSignUpForm(
    email: "user@example.com",
    password: "SecurePass123",
    confirmPassword: "SecurePass123"
)

if errors.isEmpty {
    // Form is valid, proceed with sign up
} else {
    // Show all errors
    errors.forEach { error in
        print(error.errorDescription ?? "")
    }
}
```

---

### validateSignInForm(email:password:)

**Purpose**: Validate all fields in sign-in form at once

**Preconditions**: None

**Postconditions**:
- Returns empty array if all fields valid
- Returns array of `ValidationError` for all invalid fields

**Validation Checks**:
1. Email not empty and valid format
2. Password not empty

**Note**: Password strength not checked on sign-in (only format)

**Example**:
```swift
let errors = validationService.validateSignInForm(
    email: "user@example.com",
    password: "Pass123"
)

if errors.isEmpty {
    // Form is valid, attempt sign in
} else {
    // Show errors
}
```

---

## ValidationError Definition

```swift
enum ValidationError: LocalizedError, Equatable {
    case invalidEmailFormat
    case passwordTooShort
    case passwordNoLetters
    case passwordNoNumbers
    case commonPassword
    case passwordMismatch
    case emptyField(String)  // Field name
    
    var errorDescription: String? {
        switch self {
        case .invalidEmailFormat:
            return "邮箱格式不正确"
        case .passwordTooShort:
            return "密码至少需要 8 位字符"
        case .passwordNoLetters:
            return "密码必须包含字母"
        case .passwordNoNumbers:
            return "密码必须包含数字"
        case .commonPassword:
            return "密码过于常见，请使用更复杂的密码"
        case .passwordMismatch:
            return "两次输入的密码不一致"
        case .emptyField(let field):
            return "\(field)不能为空"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmailFormat:
            return "请输入有效的邮箱地址，如：user@example.com"
        case .passwordTooShort:
            return "请输入至少 8 位字符的密码"
        case .passwordNoLetters:
            return "密码必须包含至少一个字母"
        case .passwordNoNumbers:
            return "密码必须包含至少一个数字"
        case .commonPassword:
            return "请避免使用常见密码，如"password123""
        case .passwordMismatch:
            return "请确保两次输入的密码完全一致"
        case .emptyField(let field):
            return "请填写\(field)"
        }
    }
}
```

---

## Implementation Requirements

### Email Regex Pattern

```swift
private let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
```

### Common Password List

**Storage**: Embedded in app bundle as static `Set<String>`

**Size**: Top 10,000 passwords (~50 KB)

**Source**: https://github.com/danielmiessler/SecLists/blob/master/Passwords/Common-Credentials/10k-most-common.txt

**Loading**:
```swift
struct CommonPasswords {
    static let list: Set<String> = {
        guard let url = Bundle.main.url(forResource: "common-passwords", withExtension: "txt"),
              let content = try? String(contentsOf: url) else {
            return []
        }
        return Set(content.components(separatedBy: .newlines).map { $0.lowercased() })
    }()
}
```

### Performance

- All validations must complete in < 10ms
- Email regex should be compiled once and reused
- Common password lookup O(1) using `Set`

### Thread Safety

- All methods are pure functions (no state)
- Safe to call from any thread
- Can be used concurrently

---

## Usage Example

```swift
class ValidationService: ValidationServiceProtocol {
    private let emailPredicate: NSPredicate
    
    init() {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        self.emailPredicate = NSPredicate(format: "SELF MATCHES %@", regex)
    }
    
    func validateEmail(_ email: String) -> Result<Void, ValidationError> {
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            return .failure(.emptyField("邮箱"))
        }
        
        if !emailPredicate.evaluate(with: email) {
            return .failure(.invalidEmailFormat)
        }
        
        return .success(())
    }
    
    func validatePassword(_ password: String) -> Result<Void, ValidationError> {
        if password.isEmpty {
            return .failure(.emptyField("密码"))
        }
        
        if password.count < 8 {
            return .failure(.passwordTooShort)
        }
        
        if !password.contains(where: { $0.isLetter }) {
            return .failure(.passwordNoLetters)
        }
        
        if !password.contains(where: { $0.isNumber }) {
            return .failure(.passwordNoNumbers)
        }
        
        if isCommonPassword(password) {
            return .failure(.commonPassword)
        }
        
        return .success(())
    }
    
    func isCommonPassword(_ password: String) -> Bool {
        return CommonPasswords.list.contains(password.lowercased())
    }
    
    func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length bonus
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        
        // Character variety
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 1 }
        
        // Common password penalty
        if isCommonPassword(password) { score -= 3 }
        
        switch score {
        case ...2:
            return .weak
        case 3...4:
            return .medium
        default:
            return .strong
        }
    }
    
    func validateSignUpForm(email: String, password: String, confirmPassword: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if case .failure(let error) = validateEmail(email) {
            errors.append(error)
        }
        
        if case .failure(let error) = validatePassword(password) {
            errors.append(error)
        }
        
        if password != confirmPassword {
            errors.append(.passwordMismatch)
        }
        
        return errors
    }
    
    // ... other methods
}
```

---

## Contract Tests

```swift
class ValidationServiceContractTests: XCTestCase {
    var sut: ValidationServiceProtocol!
    
    func testValidateEmailWithValidFormat() {
        // Valid emails
        XCTAssertSuccess(sut.validateEmail("user@example.com"))
        XCTAssertSuccess(sut.validateEmail("test.user@example.co.uk"))
        XCTAssertSuccess(sut.validateEmail("user+tag@example.com"))
    }
    
    func testValidateEmailWithInvalidFormat() {
        // Invalid emails
        XCTAssertFailure(sut.validateEmail(""), matching: .emptyField("邮箱"))
        XCTAssertFailure(sut.validateEmail("notanemail"), matching: .invalidEmailFormat)
        XCTAssertFailure(sut.validateEmail("@example.com"), matching: .invalidEmailFormat)
    }
    
    func testValidatePasswordWithValidPassword() {
        XCTAssertSuccess(sut.validatePassword("SecurePass123"))
        XCTAssertSuccess(sut.validatePassword("MyP@ssw0rd"))
    }
    
    func testValidatePasswordWithWeakPassword() {
        XCTAssertFailure(sut.validatePassword(""), matching: .emptyField("密码"))
        XCTAssertFailure(sut.validatePassword("short1"), matching: .passwordTooShort)
        XCTAssertFailure(sut.validatePassword("12345678"), matching: .passwordNoLetters)
        XCTAssertFailure(sut.validatePassword("password"), matching: .passwordNoNumbers)
        XCTAssertFailure(sut.validatePassword("password123"), matching: .commonPassword)
    }
    
    func testCalculatePasswordStrength() {
        XCTAssertEqual(sut.calculatePasswordStrength("Pass1"), .weak)
        XCTAssertEqual(sut.calculatePasswordStrength("SecurePass123"), .medium)
        XCTAssertEqual(sut.calculatePasswordStrength("MyP@ssw0rd2024!"), .strong)
    }
    
    func testIsCommonPassword() {
        XCTAssertTrue(sut.isCommonPassword("password"))
        XCTAssertTrue(sut.isCommonPassword("123456"))
        XCTAssertFalse(sut.isCommonPassword("MyVerySecurePass123!"))
    }
    
    func testValidateSignUpForm() {
        // Valid form
        let validErrors = sut.validateSignUpForm(
            email: "user@example.com",
            password: "SecurePass123",
            confirmPassword: "SecurePass123"
        )
        XCTAssertTrue(validErrors.isEmpty)
        
        // Invalid form
        let invalidErrors = sut.validateSignUpForm(
            email: "invalidemail",
            password: "weak",
            confirmPassword: "different"
        )
        XCTAssertGreaterThan(invalidErrors.count, 0)
    }
}
```

---

## Summary

**Capabilities**:
- ✅ Email format validation (RFC 5322 simplified)
- ✅ Password strength validation (NIST SP 800-63B compliant)
- ✅ Common password detection (10k list)
- ✅ Password strength rating
- ✅ Field emptiness validation
- ✅ Batch form validation

**Performance**:
- ✅ < 10ms per validation
- ✅ O(1) common password lookup
- ✅ Thread-safe (pure functions)

**Standards**:
- ✅ RFC 5322 (email format)
- ✅ NIST SP 800-63B (password guidelines)
- ✅ OWASP recommendations

**Localization**:
- ✅ Chinese error messages
- ✅ Chinese field names
- ✅ Recovery suggestions included

---

**Status**: ✅ Contract Defined - Ready for Implementation

**Next**: Implement `ValidationService` conforming to this protocol

---

*Last Updated*: 2025-10-20  
*Reference*: [data-model.md](../data-model.md), [plan.md](../plan.md)

