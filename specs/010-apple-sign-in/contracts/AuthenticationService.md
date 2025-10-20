# Contract: AuthenticationService

**Service**: Authentication Management  
**Purpose**: Handle user authentication operations via Firebase  
**Date**: 2025-10-20  
**Status**: Defined ✅

---

## Overview

`AuthenticationService` 是认证系统的核心服务，负责与 Firebase Authentication 交互，处理用户注册、登录、登出和密码管理操作。

---

## Protocol Definition

```swift
import Foundation
import Combine

/// Authentication service protocol for user authentication operations
protocol AuthenticationServiceProtocol {
    
    // MARK: - Sign Up
    
    /// Register a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (min 8 chars)
    /// - Returns: Newly created user object
    /// - Throws: `AuthError` if registration fails
    func signUp(email: String, password: String) async throws -> User
    
    /// Send email verification to the current user
    /// - Throws: `AuthError` if sending fails or no current user
    func sendEmailVerification() async throws
    
    // MARK: - Sign In
    
    /// Sign in an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Authenticated user object
    /// - Throws: `AuthError` if sign in fails
    func signIn(email: String, password: String) async throws -> User
    
    /// Sign out the current user
    /// - Throws: `AuthError` if sign out fails
    func signOut() throws
    
    // MARK: - Password Reset
    
    /// Send password reset email to the specified email address
    /// - Parameter email: Email address to send reset link
    /// - Throws: `AuthError` if sending fails
    func sendPasswordReset(email: String) async throws
    
    // MARK: - Current User
    
    /// Get the currently authenticated user
    /// - Returns: Current user if authenticated, nil otherwise
    func currentUser() -> User?
    
    /// Publisher for authentication state changes
    /// Emits a `User` when authenticated, `nil` when logged out
    var authStatePublisher: AnyPublisher<User?, Never> { get }
    
    // MARK: - Email Verification Status
    
    /// Reload user data from Firebase to get latest verification status
    /// - Throws: `AuthError` if reload fails
    func reloadUser() async throws
    
    /// Check if current user's email is verified
    /// - Returns: true if email is verified, false otherwise
    func isEmailVerified() -> Bool
}
```

---

## Method Specifications

### signUp(email:password:)

**Purpose**: Create a new user account with email and password

**Preconditions**:
- Email must be valid format (RFC 5322)
- Password must meet strength requirements (8+ chars, letters + numbers)
- Email must not be already registered

**Postconditions**:
- User account created in Firebase
- Verification email sent automatically
- User is NOT automatically signed in (requires email verification)
- Returns `User` object with `emailVerified = false`

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.invalidEmail` | Email format invalid | Fix email format |
| `.emailAlreadyInUse` | Email already registered | Use different email or sign in |
| `.weakPassword` | Password doesn't meet requirements | Use stronger password |
| `.networkError` | No internet connection | Check network and retry |

**Example**:
```swift
do {
    let user = try await authService.signUp(
        email: "user@example.com",
        password: "SecurePass123"
    )
    print("User created: \(user.id)")
    // Prompt user to verify email
} catch AuthError.emailAlreadyInUse {
    // Show "Email already registered" message
} catch {
    // Handle other errors
}
```

---

### sendEmailVerification()

**Purpose**: Send email verification link to current user's email

**Preconditions**:
- User must be authenticated
- User's email must not be already verified

**Postconditions**:
- Verification email sent to user's inbox
- Email contains link to verify address
- Link expires after 24 hours

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.userNotFound` | No current user | Sign in first |
| `.networkError` | No internet connection | Check network and retry |
| `.tooManyRequests` | Too many requests in short time | Wait 15 minutes |

**Example**:
```swift
do {
    try await authService.sendEmailVerification()
    // Show "Verification email sent" message
} catch AuthError.tooManyRequests {
    // Show "Please wait before requesting again"
} catch {
    // Handle other errors
}
```

---

### signIn(email:password:)

**Purpose**: Authenticate an existing user with credentials

**Preconditions**:
- Email and password provided
- User account exists in Firebase

**Postconditions**:
- User is authenticated
- Firebase ID token generated
- User object returned with latest data
- Auth state publisher emits new user

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.userNotFound` | Email not registered | Check email or sign up |
| `.wrongPassword` | Password incorrect | Check password or reset |
| `.userDisabled` | Account disabled by admin | Contact support |
| `.tooManyRequests` | Multiple failed attempts | Wait 15 minutes |
| `.networkError` | No internet connection | Check network and retry |

**Example**:
```swift
do {
    let user = try await authService.signIn(
        email: "user@example.com",
        password: "SecurePass123"
    )
    print("Signed in: \(user.email)")
    // Navigate to main app
} catch AuthError.wrongPassword {
    // Show "Invalid credentials" message
} catch {
    // Handle other errors
}
```

---

### signOut()

**Purpose**: Log out the current user

**Preconditions**:
- User must be authenticated

**Postconditions**:
- User is logged out from Firebase
- Local session cleared
- Auth state publisher emits nil
- User redirected to login screen

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.unknown` | Unexpected Firebase error | Retry or restart app |

**Example**:
```swift
do {
    try authService.signOut()
    // Navigate to login screen
} catch {
    // Log error, still navigate to login
    print("Sign out error: \(error)")
}
```

---

### sendPasswordReset(email:)

**Purpose**: Send password reset email to user

**Preconditions**:
- Email address provided
- Email format valid

**Postconditions**:
- Password reset email sent to inbox
- Email contains link to reset password
- Link expires after 1 hour

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.invalidEmail` | Email format invalid | Check email format |
| `.userNotFound` | Email not registered | Check email or sign up |
| `.networkError` | No internet connection | Check network and retry |
| `.tooManyRequests` | Too many requests | Wait 15 minutes |

**Example**:
```swift
do {
    try await authService.sendPasswordReset(email: "user@example.com")
    // Show "Password reset email sent" message
} catch AuthError.userNotFound {
    // Still show success message (security: don't reveal if email exists)
    // "If email exists, reset link was sent"
} catch {
    // Handle other errors
}
```

---

### currentUser()

**Purpose**: Get the currently authenticated user

**Preconditions**: None

**Postconditions**:
- Returns `User` object if authenticated
- Returns `nil` if not authenticated
- Does not trigger network request (local cache)

**Example**:
```swift
if let user = authService.currentUser() {
    print("Current user: \(user.email)")
} else {
    // Navigate to login
}
```

---

### authStatePublisher

**Purpose**: Observe authentication state changes reactively

**Behavior**:
- Emits `User` when user signs in
- Emits `nil` when user signs out
- Emits on subscription (current state)
- Emits on every auth state change

**Example**:
```swift
class AuthViewModel: ObservableObject {
    @Published var user: User?
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationServiceProtocol) {
        authService.authStatePublisher
            .assign(to: \.user, on: self)
            .store(in: &cancellables)
    }
}
```

---

### reloadUser()

**Purpose**: Refresh user data from Firebase to get latest email verification status

**Preconditions**:
- User must be authenticated

**Postconditions**:
- User object refreshed with latest data from server
- `emailVerified` status updated

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.userNotFound` | No current user | Sign in first |
| `.networkError` | No internet connection | Check network |

**Example**:
```swift
do {
    try await authService.reloadUser()
    if authService.isEmailVerified() {
        // Email verified, grant full access
    }
} catch {
    // Handle error
}
```

---

### isEmailVerified()

**Purpose**: Check if current user's email is verified

**Preconditions**: None

**Postconditions**:
- Returns `true` if current user exists and email is verified
- Returns `false` otherwise

**Example**:
```swift
func requireEmailVerification() throws {
    if !authService.isEmailVerified() {
        throw AuthError.emailNotVerified
    }
}
```

---

## Implementation Requirements

### Thread Safety

- All async methods must be actor-isolated or use `@MainActor`
- Publishers must emit on main thread
- Synchronous methods (`currentUser()`, `signOut()`) are thread-safe

### Error Handling

- All Firebase errors must be mapped to `AuthError`
- Unknown errors must be wrapped in `.unknown(Error)`
- Network errors must be detected and reported as `.networkError`

### Logging

- Log all authentication events (sign up, sign in, sign out)
- DO NOT log passwords or tokens
- Log errors with error codes for debugging

### Testing

- All methods must have corresponding unit tests
- Use Firebase Auth emulator for testing
- Mock Firebase for unit tests, use real Firebase for integration tests

---

## Dependencies

**Required**:
- `FirebaseAuth` framework
- `Combine` framework
- `AuthError` custom error type
- `User` data model

**Injected**:
- Firebase `Auth` instance (can be mocked for testing)

---

## Usage Example

```swift
import FirebaseAuth

class FirebaseAuthenticationService: AuthenticationServiceProtocol {
    private let auth: Auth
    private let authStateSubject = CurrentValueSubject<User?, Never>(nil)
    
    var authStatePublisher: AnyPublisher<User?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    init(auth: Auth = .auth()) {
        self.auth = auth
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.authStateSubject.send(firebaseUser.map(User.init))
        }
    }
    
    func signUp(email: String, password: String) async throws -> User {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = User(from: result.user)
            
            // Send verification email automatically
            try await sendEmailVerification()
            
            return user
        } catch {
            throw AuthError.map(from: error)
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return User(from: result.user)
        } catch {
            throw AuthError.map(from: error)
        }
    }
    
    // ... other methods
}
```

---

## Contract Tests

Required contract tests (to be implemented in Phase 2):

```swift
class AuthenticationServiceContractTests: XCTestCase {
    var sut: AuthenticationServiceProtocol!
    
    func testSignUpCreatesNewUser() async throws {
        let user = try await sut.signUp(email: "test@example.com", password: "Pass123")
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.email, "test@example.com")
    }
    
    func testSignInWithValidCredentials() async throws {
        // Given: existing user
        _ = try await sut.signUp(email: "test@example.com", password: "Pass123")
        try sut.signOut()
        
        // When: sign in with correct credentials
        let user = try await sut.signIn(email: "test@example.com", password: "Pass123")
        
        // Then: user authenticated
        XCTAssertNotNil(user)
    }
    
    func testSignInWithWrongPasswordThrows() async {
        // Given: existing user
        _ = try await sut.signUp(email: "test@example.com", password: "Pass123")
        try sut.signOut()
        
        // When: sign in with wrong password
        // Then: throws wrongPassword error
        await XCTAssertThrowsError(
            try await sut.signIn(email: "test@example.com", password: "WrongPass"),
            matching: AuthError.wrongPassword
        )
    }
    
    // ... more contract tests
}
```

---

## Summary

**Capabilities**:
- ✅ User registration (email/password)
- ✅ User sign in (email/password)
- ✅ User sign out
- ✅ Email verification
- ✅ Password reset
- ✅ Auth state observation
- ✅ Current user access

**Constraints**:
- Email verification is manual (user must click link)
- Password reset is email-based only
- Rate limiting enforced by Firebase (15 min lockout after 5 failed attempts)

**Future Extensions (Phase 2)**:
- Add `signInWithApple(credential:)` method
- Add multi-factor authentication support
- Add account linking/unlinking

---

**Status**: ✅ Contract Defined - Ready for Implementation

**Next**: Implement `FirebaseAuthenticationService` conforming to this protocol

---

*Last Updated*: 2025-10-20  
*Reference*: [data-model.md](../data-model.md), [plan.md](../plan.md)

