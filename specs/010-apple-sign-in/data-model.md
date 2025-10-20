# Data Model: Firebase 邮箱登录系统

**Feature**: Firebase 邮箱登录系统  
**Date**: 2025-10-20  
**Status**: Complete ✅

## Overview

本文档定义了认证系统的核心数据模型，包括实体定义、关系、验证规则和状态转换。

---

## Entity Definitions

### 1. User (用户)

**Description**: 表示一个已注册的用户账号

**Source**: Firebase Authentication + Custom fields

```swift
struct User: Identifiable, Codable, Equatable {
    // MARK: - Identity
    let id: String                      // Firebase UID (唯一标识符)
    let email: String                   // 用户邮箱
    
    // MARK: - Profile
    var displayName: String?            // 显示名称（可选）
    var photoURL: URL?                  // 头像 URL（可选）
    
    // MARK: - Metadata
    let createdAt: Date                 // 账号创建时间
    var lastLoginAt: Date               // 最后登录时间
    var emailVerified: Bool             // 邮箱验证状态
    
    // MARK: - Authentication
    let authMethod: AuthenticationMethod // 登录方式
    
    // MARK: - Preferences (Local/Firestore)
    var rememberMe: Bool                // 记住登录状态
    var theme: AppTheme                 // 主题偏好
    var language: String                // 语言偏好
    
    // MARK: - Computed Properties
    var isEmailVerified: Bool {
        return emailVerified
    }
    
    var initials: String {
        guard let name = displayName, !name.isEmpty else {
            return email.prefix(1).uppercased()
        }
        return name.prefix(1).uppercased()
    }
}
```

**Field Validation Rules**:

| Field | Type | Required | Constraints | Default |
|-------|------|----------|-------------|---------|
| `id` | String | ✅ | Firebase UID (28 chars) | - |
| `email` | String | ✅ | RFC 5322 format, unique | - |
| `displayName` | String? | ❌ | 1-50 chars | nil |
| `photoURL` | URL? | ❌ | Valid HTTP(S) URL | nil |
| `createdAt` | Date | ✅ | <= now | Account creation time |
| `lastLoginAt` | Date | ✅ | <= now | Last login time |
| `emailVerified` | Bool | ✅ | - | false |
| `authMethod` | Enum | ✅ | .email or .apple | .email |
| `rememberMe` | Bool | ✅ | - | false |
| `theme` | Enum | ✅ | .light, .dark, .system | .system |
| `language` | String | ✅ | ISO 639-1 code | "zh" |

**Firebase Mapping**:
```swift
extension User {
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL
        self.createdAt = firebaseUser.metadata.creationDate ?? Date()
        self.lastLoginAt = firebaseUser.metadata.lastSignInDate ?? Date()
        self.emailVerified = firebaseUser.isEmailVerified
        self.authMethod = .email  // Phase 1: 仅邮箱登录
        // 从 Firestore 加载偏好设置
        self.rememberMe = false
        self.theme = .system
        self.language = Locale.current.languageCode ?? "zh"
    }
}
```

---

### 2. UserSession (用户会话)

**Description**: 表示一个活跃的用户登录会话

**Lifecycle**: Created on login → Active → Expired/Logged out

```swift
struct UserSession: Codable, Equatable {
    // MARK: - Session Identity
    let sessionId: String               // 会话唯一标识符
    let user: User                      // 关联的用户
    
    // MARK: - Token Management
    let token: String                   // Firebase ID Token (1 hour TTL)
    let refreshToken: String            // Firebase Refresh Token
    
    // MARK: - Session Metadata
    let createdAt: Date                 // 会话创建时间
    let expiresAt: Date                 // 会话过期时间
    let rememberMe: Bool                // 是否记住登录
    
    // MARK: - Device Information
    var deviceId: String?               // 设备标识符（可选）
    var deviceName: String?             // 设备名称（可选）
    var lastActivityAt: Date            // 最后活跃时间
    
    // MARK: - Computed Properties
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var isActive: Bool {
        return !isExpired
    }
    
    var sessionDuration: TimeInterval {
        return rememberMe ? 90 * 24 * 3600 : 30 * 24 * 3600
    }
}
```

**Field Validation Rules**:

| Field | Type | Required | Constraints | Default |
|-------|------|----------|-------------|---------|
| `sessionId` | String | ✅ | UUID format | UUID() |
| `user` | User | ✅ | Valid user object | - |
| `token` | String | ✅ | Firebase ID Token | - |
| `refreshToken` | String | ✅ | Firebase Refresh Token | - |
| `createdAt` | Date | ✅ | <= now | Current time |
| `expiresAt` | Date | ✅ | > now, <= now + 90 days | createdAt + 30/90 days |
| `rememberMe` | Bool | ✅ | - | false |
| `deviceId` | String? | ❌ | UUID format | nil |
| `deviceName` | String? | ❌ | 1-100 chars | nil |
| `lastActivityAt` | Date | ✅ | <= now | Current time |

**State Transitions**:
```
[Not Logged In] 
    ↓ signIn()
[Active Session] ──┐
    ↓               │ refreshSession()
[Token Expired]    │ (< expiresAt)
    ↓               │
[Session Expired] ←┘
    ↓ signOut() or > expiresAt
[Not Logged In]
```

---

### 3. AuthenticationMethod (登录方式)

**Description**: 用户使用的认证方法枚举

```swift
enum AuthenticationMethod: String, Codable, CaseIterable {
    case email = "email"        // 邮箱/密码登录（Phase 1）
    case apple = "apple"        // Apple Sign In（Phase 2）
    
    var displayName: String {
        switch self {
        case .email:
            return "邮箱登录"
        case .apple:
            return "Apple 登录"
        }
    }
    
    var icon: String {
        switch self {
        case .email:
            return "envelope.fill"
        case .apple:
            return "applelogo"
        }
    }
}
```

---

### 4. AuthError (认证错误)

**Description**: 自定义认证错误类型，提供用户友好的错误消息

```swift
enum AuthError: LocalizedError, Equatable {
    // MARK: - Input Validation Errors
    case invalidEmail
    case weakPassword
    case passwordTooShort
    case passwordNoLetters
    case passwordNoNumbers
    case commonPassword
    
    // MARK: - Authentication Errors
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case emailNotVerified
    case userDisabled
    
    // MARK: - Network Errors
    case networkError
    case timeout
    
    // MARK: - Rate Limiting
    case tooManyRequests
    
    // MARK: - Unknown
    case unknown(Error?)
    
    // MARK: - Error Description (用户可见)
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "邮箱格式不正确"
        case .weakPassword:
            return "密码强度不足"
        case .passwordTooShort:
            return "密码至少需要 8 位字符"
        case .passwordNoLetters:
            return "密码必须包含字母"
        case .passwordNoNumbers:
            return "密码必须包含数字"
        case .commonPassword:
            return "密码过于常见，请使用更复杂的密码"
        case .emailAlreadyInUse:
            return "该邮箱已被注册"
        case .userNotFound:
            return "账号不存在"
        case .wrongPassword:
            return "邮箱或密码错误"
        case .emailNotVerified:
            return "请先验证您的邮箱"
        case .userDisabled:
            return "该账号已被禁用"
        case .networkError:
            return "网络连接失败"
        case .timeout:
            return "连接超时"
        case .tooManyRequests:
            return "操作过于频繁，请稍后再试"
        case .unknown(let error):
            return "发生未知错误：\(error?.localizedDescription ?? "未知")"
        }
    }
    
    // MARK: - Recovery Suggestion (恢复建议)
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "请检查邮箱格式是否正确"
        case .weakPassword, .passwordTooShort, .passwordNoLetters, .passwordNoNumbers:
            return "密码需要至少 8 位字符，包含字母和数字"
        case .commonPassword:
            return "请避免使用常见密码，如"12345678"或"password""
        case .emailAlreadyInUse:
            return "该邮箱已注册，请直接登录或使用其他邮箱"
        case .userNotFound, .wrongPassword:
            return "请检查您的登录信息，或点击\"忘记密码\""
        case .emailNotVerified:
            return "请查收验证邮件并点击链接完成验证"
        case .userDisabled:
            return "请联系客服恢复账号"
        case .networkError:
            return "请检查网络连接后重试"
        case .timeout:
            return "请检查网络状况或稍后重试"
        case .tooManyRequests:
            return "您的账号已被临时锁定 15 分钟，请稍后再试"
        case .unknown:
            return "请重试或联系客服"
        }
    }
    
    // MARK: - Firebase Error Mapping
    static func map(from error: Error) -> AuthError {
        let nsError = error as NSError
        let errorCode = AuthErrorCode(_nsError: nsError)
        
        switch errorCode.code {
        case .invalidEmail:
            return .invalidEmail
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .wrongPassword
        case .userDisabled:
            return .userDisabled
        case .networkError:
            return .networkError
        case .tooManyRequests:
            return .tooManyRequests
        default:
            return .unknown(error)
        }
    }
}
```

---

### 5. ValidationError (验证错误)

**Description**: 输入验证错误类型

```swift
enum ValidationError: LocalizedError, Equatable {
    case invalidEmailFormat
    case passwordTooShort
    case passwordNoLetters
    case passwordNoNumbers
    case commonPassword
    case emptyField(String)  // 字段名
    
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
            return "密码过于常见"
        case .emptyField(let field):
            return "\(field)不能为空"
        }
    }
}
```

---

### 6. PasswordStrength (密码强度)

**Description**: 密码强度评估

```swift
enum PasswordStrength: Int, Comparable {
    case weak = 0
    case medium = 1
    case strong = 2
    
    var displayName: String {
        switch self {
        case .weak:
            return "弱"
        case .medium:
            return "中"
        case .strong:
            return "强"
        }
    }
    
    var color: Color {
        switch self {
        case .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return .green
        }
    }
    
    static func < (lhs: PasswordStrength, rhs: PasswordStrength) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
```

---

### 7. AppTheme (应用主题)

**Description**: 应用主题偏好

```swift
enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light:
            return "浅色"
        case .dark:
            return "深色"
        case .system:
            return "跟随系统"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil  // 使用系统设置
        }
    }
}
```

---

## Entity Relationships

```
┌──────────────────────────┐
│         User             │
│  - id: String            │
│  - email: String         │
│  - authMethod: Enum      │
│  - emailVerified: Bool   │
└────────────┬─────────────┘
             │ 1
             │ has
             │ 0..n
┌────────────┴─────────────┐
│      UserSession         │
│  - sessionId: String     │
│  - user: User            │
│  - token: String         │
│  - expiresAt: Date       │
└──────────────────────────┘

┌──────────────────────────┐
│  AuthenticationMethod    │
│  (enum)                  │
│  - email                 │
│  - apple                 │
└──────────────────────────┘
             ↑
             │ uses
             │
┌────────────┴─────────────┐
│         User             │
└──────────────────────────┘

┌──────────────────────────┐
│       AuthError          │
│  (enum)                  │
│  + errorDescription      │
│  + recoverySuggestion    │
└──────────────────────────┘
             ↑
             │ throws
             │
┌────────────┴─────────────┐
│  AuthenticationService   │
│  + signUp()              │
│  + signIn()              │
│  + signOut()             │
└──────────────────────────┘
```

---

## Data Storage

### Local Storage (Keychain)

**Stored Data**:
```swift
// Keychain items
keychain.set(user.id, key: "userId")
keychain.set(session.token, key: "authToken")
keychain.set(session.refreshToken, key: "refreshToken")
```

**Security**:
- All tokens stored with `kSecAttrAccessibleWhenUnlocked`
- Automatic deletion on app uninstall
- Face ID/Touch ID protection (optional)

### Local Storage (UserDefaults)

**Stored Data**:
```swift
// User preferences
UserDefaults.standard.set(session.expiresAt, forKey: "sessionExpiresAt")
UserDefaults.standard.set(user.rememberMe, forKey: "rememberMe")
UserDefaults.standard.set(user.theme.rawValue, forKey: "appTheme")
UserDefaults.standard.set(user.language, forKey: "appLanguage")
```

**Note**: 不存储敏感信息（密码、token）在 UserDefaults

### Remote Storage (Firestore)

**Collection Structure**:
```
users/ (collection)
├── {userId}/ (document)
│   ├── id: String
│   ├── email: String
│   ├── displayName: String?
│   ├── photoURL: String?
│   ├── createdAt: Timestamp
│   ├── emailVerified: Boolean
│   ├── authMethod: String
│   ├── preferences/
│   │   ├── theme: String
│   │   ├── language: String
│   │   └── rememberMe: Boolean
│   └── events/ (sub-collection)
│       └── {eventId}/ (document)
│           └── ... (日历事件数据)
```

**Firestore Security Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能读写自己的数据
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // 事件子集合
      match /events/{eventId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

## State Transitions

### User Authentication State

```
┌─────────────────┐
│  Unauthenticated │
│  (Anonymous)     │
└────────┬─────────┘
         │
         │ signUp() / signIn()
         ↓
┌────────────────────┐
│  Authenticated     │
│  (Logged In)       │
│  emailVerified=?   │
└────────┬───────────┘
         │
         ├──→ emailVerified == false ──→ [Limited Access]
         │    (可登录，部分功能受限)
         │
         └──→ emailVerified == true ──→ [Full Access]
              (完整功能)
         
         │ signOut() / session expires
         ↓
┌─────────────────┐
│  Unauthenticated │
└─────────────────┘
```

### Session Lifecycle

```
[No Session]
    ↓ signIn(email, password)
[Creating Session]
    ↓ Firebase Auth Success
[Session Active]
    │
    ├──→ < 1 hour ──→ [Token Expired] ──→ Auto Refresh ──→ [Session Active]
    │
    ├──→ 30/90 days ──→ [Session Expired] ──→ Require Re-login ──→ [No Session]
    │
    └──→ signOut() ──→ [No Session]
```

### Email Verification Flow

```
[User Registers]
    ↓
[Account Created]
    │ emailVerified = false
    │
    ↓ sendEmailVerification()
[Verification Email Sent]
    │
    ↓ User clicks link
[Email Verified]
    │ Firebase updates emailVerified = true
    │
    ↓ App checks status
[Full Access Granted]
```

---

## Validation Rules

### Email Validation

```swift
func validateEmail(_ email: String) -> Result<Void, ValidationError> {
    let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
    let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    
    if email.isEmpty {
        return .failure(.emptyField("邮箱"))
    }
    
    if !predicate.evaluate(with: email) {
        return .failure(.invalidEmailFormat)
    }
    
    return .success(())
}
```

### Password Validation

```swift
func validatePassword(_ password: String) -> Result<Void, ValidationError> {
    // 长度检查
    if password.count < 8 {
        return .failure(.passwordTooShort)
    }
    
    // 必须包含字母
    if !password.contains(where: { $0.isLetter }) {
        return .failure(.passwordNoLetters)
    }
    
    // 必须包含数字
    if !password.contains(where: { $0.isNumber }) {
        return .failure(.passwordNoNumbers)
    }
    
    // 检查常见弱密码
    if CommonPasswords.list.contains(password.lowercased()) {
        return .failure(.commonPassword)
    }
    
    return .success(())
}

func calculatePasswordStrength(_ password: String) -> PasswordStrength {
    var score = 0
    
    // 长度 bonus
    if password.count >= 12 { score += 1 }
    if password.count >= 16 { score += 1 }
    
    // 字符种类 bonus
    if password.contains(where: { $0.isUppercase }) { score += 1 }
    if password.contains(where: { $0.isLowercase }) { score += 1 }
    if password.contains(where: { $0.isNumber }) { score += 1 }
    if password.contains(where: { !$0.isLetterOrNumber }) { score += 1 }
    
    // 映射到强度等级
    switch score {
    case 0...2:
        return .weak
    case 3...4:
        return .medium
    default:
        return .strong
    }
}
```

### Common Weak Passwords

```swift
struct CommonPasswords {
    static let list: Set<String> = [
        "12345678", "password", "123456789", "12345", "1234567",
        "password1", "123123", "qwerty", "abc123", "111111",
        "123321", "password123", "1234567890", "000000", "qwerty123"
        // ... (完整列表约 10,000 个)
    ]
}
```

---

## Performance Considerations

### Caching Strategy

**In-Memory Cache**:
- `currentUser`: 当前用户对象（单例）
- `currentSession`: 当前会话对象（单例）

**Cache Invalidation**:
- 登出时清除所有缓存
- Token 刷新时更新缓存
- 用户信息更新时重新加载

### Firestore Query Optimization

```swift
// 使用索引查询
db.collection("users").document(userId)  // 直接文档访问，O(1)

// 避免 collection group queries
// 所有数据都在 users/{userId}/ 下，不跨文档查询

// 启用离线持久化
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
db.settings = settings
```

---

## Security Considerations

### Data Encryption

**At Rest**:
- Keychain: iOS 系统加密
- Firestore: Google 自动加密

**In Transit**:
- Firebase: TLS 1.3
- All API calls over HTTPS

### Sensitive Data Handling

**Never Store**:
- ❌ Plain text passwords
- ❌ Credit card information
- ❌ Social security numbers

**Secure Storage**:
- ✅ Tokens in Keychain
- ✅ User ID in Keychain
- ✅ Session expiry in UserDefaults (non-sensitive)

---

## Summary

### Core Entities

| Entity | Purpose | Storage | Lifecycle |
|--------|---------|---------|-----------|
| **User** | User account | Firebase Auth + Firestore | Persistent |
| **UserSession** | Active login session | Keychain + UserDefaults | 30/90 days |
| **AuthenticationMethod** | Login method | Enum (code only) | - |
| **AuthError** | Error handling | Enum (code only) | - |
| **ValidationError** | Input validation | Enum (code only) | - |
| **PasswordStrength** | Password rating | Enum (code only) | - |
| **AppTheme** | UI theme | UserDefaults + Firestore | Persistent |

### Key Validations

- ✅ Email: RFC 5322 format
- ✅ Password: 8+ chars, letters + numbers
- ✅ Common password check (top 10k list)
- ✅ Real-time + submit validation

### Security Measures

- ✅ Keychain for sensitive data
- ✅ TLS 1.3 encryption
- ✅ Firestore security rules
- ✅ Token auto-refresh
- ✅ Session expiration (30/90 days)

---

**Status**: ✅ Data Model Complete - Ready for Contract Definition

**Next Steps**:
1. Generate service contracts (protocols)
2. Implement models with unit tests
3. Generate quickstart guide

---

*Last Updated*: 2025-10-20  
*Reference*: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md)

