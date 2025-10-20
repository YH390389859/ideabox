# Contract: UserSessionManager

**Service**: Session Management  
**Purpose**: Manage user session lifecycle, persistence, and expiration  
**Date**: 2025-10-20  
**Status**: Defined ✅

---

## Overview

`UserSessionManager` 负责管理用户登录会话的完整生命周期，包括会话创建、持久化存储、自动刷新、过期检测和清理。

---

## Protocol Definition

```swift
import Foundation
import Combine

/// User session management protocol
protocol UserSessionManagerProtocol {
    
    // MARK: - Session State
    
    /// Whether a user is currently authenticated
    var isAuthenticated: Bool { get }
    
    /// The currently authenticated user
    var currentUser: User? { get }
    
    /// Publisher for session state changes
    /// Emits `UserSession` when active, `nil` when logged out
    var sessionPublisher: AnyPublisher<UserSession?, Never> { get }
    
    // MARK: - Session Management
    
    /// Start a new session for the authenticated user
    /// - Parameters:
    ///   - user: The authenticated user
    ///   - rememberMe: Whether to extend session to 90 days (default: false, 30 days)
    /// - Throws: `AuthError` if session creation fails
    func startSession(user: User, rememberMe: Bool) async throws
    
    /// End the current session and clear all session data
    /// - Throws: `AuthError` if session cleanup fails
    func endSession() async throws
    
    /// Refresh the current session (update token and expiry)
    /// - Throws: `AuthError` if refresh fails or no active session
    func refreshSession() async throws
    
    // MARK: - Session Persistence
    
    /// Load a previously persisted session from local storage
    /// - Returns: Persisted session if valid, nil if expired or not found
    func loadPersistedSession() async -> UserSession?
    
    /// Clear all persisted session data from local storage
    /// - Throws: `AuthError` if cleanup fails
    func clearPersistedSession() async throws
    
    // MARK: - Session Validation
    
    /// Check if the current session is still valid (not expired)
    /// - Returns: true if session is active and not expired
    func isSessionValid() -> Bool
    
    /// Get the time remaining until session expires
    /// - Returns: Time interval in seconds, or nil if no session
    func timeUntilExpiry() -> TimeInterval?
}
```

---

## Method Specifications

### isAuthenticated

**Purpose**: Check if a user is currently authenticated with an active session

**Behavior**:
- Returns `true` if `currentUser` is not nil AND session is not expired
- Returns `false` otherwise
- Synchronous property (no network call)

**Example**:
```swift
if sessionManager.isAuthenticated {
    // Show main app
} else {
    // Show login screen
}
```

---

### currentUser

**Purpose**: Get the currently authenticated user

**Behavior**:
- Returns `User` object if session is active
- Returns `nil` if no session or session expired
- Synchronous property (cached)

**Example**:
```swift
if let user = sessionManager.currentUser {
    print("Welcome, \(user.email)")
}
```

---

### sessionPublisher

**Purpose**: Observe session state changes reactively

**Behavior**:
- Emits `UserSession` when session starts
- Emits `nil` when session ends or expires
- Emits on subscription (current state)
- Emits on every session state change

**Example**:
```swift
class RootViewModel: ObservableObject {
    @Published var isLoggedIn = false
    private var cancellables = Set<AnyCancellable>()
    
    init(sessionManager: UserSessionManagerProtocol) {
        sessionManager.sessionPublisher
            .map { $0 != nil }
            .assign(to: \.isLoggedIn, on: self)
            .store(in: &cancellables)
    }
}
```

---

### startSession(user:rememberMe:)

**Purpose**: Create and persist a new user session after successful authentication

**Preconditions**:
- User must be authenticated (have valid Firebase token)
- User object must be valid

**Postconditions**:
- Session created with unique session ID
- Session token stored in Keychain
- Session expiry time calculated and stored
- User preferences saved
- `sessionPublisher` emits new session
- `isAuthenticated` becomes `true`

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `user` | User | Authenticated user object |
| `rememberMe` | Bool | If true, session lasts 90 days; if false, 30 days |

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.unknown` | Keychain save fails | Retry or restart app |

**Example**:
```swift
do {
    let user = try await authService.signIn(email: "user@example.com", password: "Pass123")
    try await sessionManager.startSession(user: user, rememberMe: true)
    // Session created, navigate to main app
} catch {
    // Handle error
}
```

---

### endSession()

**Purpose**: Terminate the current session and clean up all session data

**Preconditions**:
- Should be called when user explicitly logs out or session expires

**Postconditions**:
- Session data cleared from Keychain
- Session preferences cleared from UserDefaults
- `sessionPublisher` emits `nil`
- `isAuthenticated` becomes `false`
- `currentUser` becomes `nil`

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.unknown` | Keychain delete fails | Log error, continue logout |

**Example**:
```swift
do {
    try await sessionManager.endSession()
    // Navigate to login screen
} catch {
    // Log error but still navigate to login
    print("Session cleanup error: \(error)")
}
```

---

### refreshSession()

**Purpose**: Update the session with fresh token and extend expiry time

**Preconditions**:
- Active session must exist
- Firebase must have valid refresh token

**Postconditions**:
- Session token updated in Keychain
- Session expiry time updated
- `lastActivityAt` updated to current time
- `sessionPublisher` emits updated session

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.userNotFound` | No active session | Sign in again |
| `.networkError` | No internet | Check connection |

**Example**:
```swift
// Typically called automatically by the service
do {
    try await sessionManager.refreshSession()
    // Session refreshed successfully
} catch AuthError.userNotFound {
    // Session invalid, redirect to login
}
```

---

### loadPersistedSession()

**Purpose**: Restore a previously saved session from local storage on app launch

**Preconditions**: None

**Postconditions**:
- If valid session found:
  - Session restored to memory
  - `sessionPublisher` emits restored session
  - `isAuthenticated` becomes `true`
- If no session or expired:
  - Returns `nil`
  - User remains logged out

**Returns**: `UserSession?` - Restored session or nil

**Example**:
```swift
// Called in App init or on launch
Task {
    if let session = await sessionManager.loadPersistedSession() {
        print("Restored session for user: \(session.user.email)")
        // User stays logged in
    } else {
        // Show login screen
    }
}
```

---

### clearPersistedSession()

**Purpose**: Delete all persisted session data from local storage

**Preconditions**: None (idempotent)

**Postconditions**:
- All Keychain items removed
- All UserDefaults entries removed
- No session data remains on device

**Error Cases**:
| Error | Condition | User Action |
|-------|-----------|-------------|
| `.unknown` | Storage access fails | Retry |

**Example**:
```swift
// Called when user uninstalls or resets app data
do {
    try await sessionManager.clearPersistedSession()
    // All session data deleted
} catch {
    // Handle error
}
```

---

### isSessionValid()

**Purpose**: Check if the current session is still valid and not expired

**Preconditions**: None

**Postconditions**: None (read-only check)

**Returns**: `Bool` - true if session active and not expired

**Example**:
```swift
if !sessionManager.isSessionValid() {
    // Session expired, show login
    try await sessionManager.endSession()
}
```

---

### timeUntilExpiry()

**Purpose**: Calculate time remaining until current session expires

**Preconditions**: None

**Postconditions**: None (read-only calculation)

**Returns**: `TimeInterval?` - Seconds until expiry, or nil if no session

**Example**:
```swift
if let timeLeft = sessionManager.timeUntilExpiry() {
    let days = Int(timeLeft / (24 * 3600))
    print("Session expires in \(days) days")
}
```

---

## Session Lifecycle

```
[App Launch]
    ↓
loadPersistedSession()
    ↓
    ├─→ Session Found & Valid ──→ [Logged In]
    │                                │
    │                                ├─→ User Activity ──→ Update lastActivityAt
    │                                │
    │                                ├─→ 30/90 Days Pass ──→ [Expired] ──→ endSession()
    │                                │
    │                                └─→ User Logs Out ──→ endSession() ──→ [Logged Out]
    │
    └─→ No Session / Expired ──→ [Logged Out]
              ↓
        [User Signs In]
              ↓
        startSession()
              ↓
        [Logged In]
```

---

## Storage Strategy

### Keychain (Sensitive Data)

**Keys**:
- `userId`: User's unique ID
- `authToken`: Firebase ID token
- `refreshToken`: Firebase refresh token
- `sessionId`: Session unique identifier

**Security**:
- `kSecAttrAccessibleWhenUnlocked`: Data accessible only when device unlocked
- Automatic deletion on app uninstall
- Optional Face ID/Touch ID protection

### UserDefaults (Non-Sensitive Metadata)

**Keys**:
- `sessionExpiresAt`: Session expiration date
- `rememberMe`: Remember me preference
- `lastActivityAt`: Last user activity timestamp

**Note**: Never store tokens or passwords in UserDefaults

---

## Implementation Requirements

### Automatic Token Refresh

- Monitor Firebase auth state changes
- Automatically refresh token before expiry (< 1 hour)
- Update Keychain with new token
- Silent refresh (no user interaction)

### Session Expiry Monitoring

- Check expiry on app foreground
- Periodic checks during app use (every 5 minutes)
- Automatic logout on expiry

### Background Handling

- Save session state on app background
- Restore session state on app foreground
- Handle token refresh in background

### Logging

- Log session start/end events
- Log session refresh events
- Log session expiry events
- DO NOT log tokens or sensitive data

---

## Dependencies

**Required**:
- `KeychainAccess` library for secure storage
- `User` data model
- `UserSession` data model
- `AuthError` error type

**Injected**:
- Firebase `Auth` instance (for token management)
- Keychain service
- UserDefaults service

---

## Usage Example

```swift
import Foundation
import KeychainAccess
import Combine

class UserSessionManager: UserSessionManagerProtocol {
    private let keychain = Keychain(service: "com.ideabox.auth")
    private let defaults = UserDefaults.standard
    private let sessionSubject = CurrentValueSubject<UserSession?, Never>(nil)
    
    var sessionPublisher: AnyPublisher<UserSession?, Never> {
        sessionSubject.eraseToAnyPublisher()
    }
    
    var isAuthenticated: Bool {
        guard let session = sessionSubject.value else { return false }
        return !session.isExpired
    }
    
    var currentUser: User? {
        return sessionSubject.value?.user
    }
    
    func startSession(user: User, rememberMe: Bool) async throws {
        let sessionId = UUID().uuidString
        let duration: TimeInterval = rememberMe ? 90 * 24 * 3600 : 30 * 24 * 3600
        let expiresAt = Date().addingTimeInterval(duration)
        
        // Get Firebase token
        guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
            throw AuthError.unknown(nil)
        }
        
        // Store in Keychain
        try keychain.set(user.id, key: "userId")
        try keychain.set(token, key: "authToken")
        try keychain.set(sessionId, key: "sessionId")
        
        // Store metadata in UserDefaults
        defaults.set(expiresAt, forKey: "sessionExpiresAt")
        defaults.set(rememberMe, forKey: "rememberMe")
        defaults.set(Date(), forKey: "lastActivityAt")
        
        // Create session object
        let session = UserSession(
            sessionId: sessionId,
            user: user,
            token: token,
            refreshToken: "", // Managed by Firebase
            createdAt: Date(),
            expiresAt: expiresAt,
            rememberMe: rememberMe,
            deviceId: nil,
            deviceName: nil,
            lastActivityAt: Date()
        )
        
        // Publish session
        sessionSubject.send(session)
    }
    
    func endSession() async throws {
        // Clear Keychain
        try keychain.removeAll()
        
        // Clear UserDefaults
        defaults.removeObject(forKey: "sessionExpiresAt")
        defaults.removeObject(forKey: "rememberMe")
        defaults.removeObject(forKey: "lastActivityAt")
        
        // Publish nil session
        sessionSubject.send(nil)
    }
    
    func loadPersistedSession() async -> UserSession? {
        // Check if session exists and not expired
        guard let expiresAt = defaults.object(forKey: "sessionExpiresAt") as? Date,
              expiresAt > Date(),
              let userId = try? keychain.get("userId"),
              let token = try? keychain.get("authToken"),
              let sessionId = try? keychain.get("sessionId") else {
            return nil
        }
        
        // Verify Firebase token is still valid
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        
        let user = User(from: firebaseUser)
        let rememberMe = defaults.bool(forKey: "rememberMe")
        
        let session = UserSession(
            sessionId: sessionId,
            user: user,
            token: token,
            refreshToken: "",
            createdAt: Date(),
            expiresAt: expiresAt,
            rememberMe: rememberMe,
            deviceId: nil,
            deviceName: nil,
            lastActivityAt: Date()
        )
        
        sessionSubject.send(session)
        return session
    }
    
    // ... other methods
}
```

---

## Contract Tests

```swift
class UserSessionManagerContractTests: XCTestCase {
    var sut: UserSessionManagerProtocol!
    var mockUser: User!
    
    func testStartSessionCreatesValidSession() async throws {
        // When: start session
        try await sut.startSession(user: mockUser, rememberMe: false)
        
        // Then: session is active
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.id, mockUser.id)
    }
    
    func testEndSessionClearsSessionData() async throws {
        // Given: active session
        try await sut.startSession(user: mockUser, rememberMe: false)
        
        // When: end session
        try await sut.endSession()
        
        // Then: session cleared
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }
    
    func testLoadPersistedSessionRestoresSession() async throws {
        // Given: session created and persisted
        try await sut.startSession(user: mockUser, rememberMe: true)
        
        // When: load persisted session (simulate app restart)
        let restoredSession = await sut.loadPersistedSession()
        
        // Then: session restored
        XCTAssertNotNil(restoredSession)
        XCTAssertEqual(restoredSession?.user.id, mockUser.id)
    }
    
    func testSessionExpiryInvalidatesSession() async throws {
        // Given: session with short expiry
        try await sut.startSession(user: mockUser, rememberMe: false)
        
        // When: time passes beyond expiry (mock time)
        // ... (use time mocking)
        
        // Then: session is invalid
        XCTAssertFalse(sut.isSessionValid())
    }
}
```

---

## Summary

**Capabilities**:
- ✅ Session creation and storage
- ✅ Session persistence (Keychain + UserDefaults)
- ✅ Session restoration on app launch
- ✅ Automatic token refresh
- ✅ Session expiry detection
- ✅ Clean session termination
- ✅ Reactive session state observation

**Security**:
- ✅ Tokens stored in Keychain (encrypted)
- ✅ Automatic cleanup on logout
- ✅ Session expiry enforcement
- ✅ Device-specific sessions

**Session Durations**:
- Default: 30 days
- Remember Me: 90 days
- Token refresh: Every 1 hour (Firebase automatic)

---

**Status**: ✅ Contract Defined - Ready for Implementation

**Next**: Implement `UserSessionManager` conforming to this protocol

---

*Last Updated*: 2025-10-20  
*Reference*: [data-model.md](../data-model.md), [plan.md](../plan.md)

