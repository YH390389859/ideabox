# Tasks: Firebase 邮箱登录系统 (Phase 1)

**Input**: Design documents from `/specs/010-apple-sign-in/`  
**Prerequisites**: ✅ plan.md, ✅ research.md, ✅ data-model.md, ✅ contracts/, ✅ quickstart.md  
**Branch**: `010-apple-sign-in`  
**Estimated Time**: 2-3 days (16-24 hours)

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → ✅ Extracted: Swift 5.9+, SwiftUI, Firebase 10.0+, MVVM architecture
2. Load optional design documents:
   → ✅ data-model.md: 7 entities (User, UserSession, AuthError, etc.)
   → ✅ contracts/: 3 service protocols
   → ✅ research.md: 9 technical decisions
   → ✅ quickstart.md: Firebase setup and test scenarios
3. Generate tasks by category:
   → Setup: Firebase config, folder structure (4 tasks)
   → Models: 7 entity implementations (7 tasks)
   → Protocols: 3 service interfaces (3 tasks)
   → Tests: Contract tests + Integration tests (7 tasks)
   → Services: 3 service implementations (3 tasks)
   → ViewModels: 3 view model implementations (3 tasks)
   → Views: 8 UI components (8 tasks)
   → Integration: App integration (2 tasks)
   → Polish: Documentation, tests, VoiceOver (3 tasks)
4. Apply task rules:
   → Different files = marked [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001-T040)
6. Dependencies validated
7. Parallel execution examples provided
8. ✅ Task completeness validated
```

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions
- Estimated time per task: 30-90 minutes

---

## Path Conventions

**iOS Project Structure**:
```
IdeaBox/Authentication/                   # Feature module
├── Models/                               # Data entities
├── Services/                             # Business logic
├── ViewModels/                           # Presentation logic
└── Views/                                # UI components
    └── Components/                       # Reusable components

IdeaBoxTests/Authentication/              # Tests
├── Services/                             # Unit tests
├── ViewModels/                           # ViewModel tests
└── Integration/                          # End-to-end tests
```

---

## Phase 3.1: Setup & Infrastructure (4 tasks, ~2 hours)

### T001: Firebase 项目配置
**Description**: 按照 quickstart.md 完成 Firebase 项目设置  
**File**: External (Firebase Console)  
**Time**: 15 minutes  
**Actions**:
- 创建 Firebase 项目 "ideabox"
- 添加 iOS 应用（Bundle ID: com.yourcompany.ideabox）
- 下载 GoogleService-Info.plist
- 启用 Email/Password 认证
- 配置邮件模板（验证邮件、密码重置）

**Acceptance Criteria**:
- Firebase 项目已创建
- iOS 应用已注册
- Email/Password 认证已启用
- GoogleService-Info.plist 已下载

---

### T002: 添加 Firebase SDK 依赖
**Description**: 通过 SPM 添加 Firebase iOS SDK  
**File**: `IdeaBox.xcodeproj` (Xcode project settings)  
**Time**: 10 minutes  
**Actions**:
1. File → Add Package Dependencies
2. 添加 https://github.com/firebase/firebase-ios-sdk
3. 选择 FirebaseAuth 和 FirebaseFirestore
4. 等待下载完成

**Acceptance Criteria**:
- Firebase SDK 添加成功
- 项目可以编译无错误
- Package.resolved 已更新

**Dependency**: After T001

---

### T003: 初始化 Firebase 和添加配置文件
**Description**: 配置 Firebase 初始化和添加 GoogleService-Info.plist  
**Files**: 
- `IdeaBox/GoogleService-Info.plist` (添加)
- `IdeaBox/IdeaBoxApp.swift` (修改)
**Time**: 15 minutes  
**Actions**:
1. 将 GoogleService-Info.plist 添加到 Xcode 项目
2. 确保 Target Membership 勾选 IdeaBox
3. 在 IdeaBoxApp.swift 的 init() 中添加 `FirebaseApp.configure()`

**Code**:
```swift
import SwiftUI
import FirebaseCore

@main
struct IdeaBoxApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Acceptance Criteria**:
- GoogleService-Info.plist 在项目中
- Firebase 初始化代码已添加
- 运行应用时控制台显示 Firebase 初始化日志
- 应用可以正常运行

**Dependency**: After T002

---

### T004: 创建 Authentication 模块文件夹结构
**Description**: 创建认证功能的文件夹结构  
**Files**: Folder structure in Xcode  
**Time**: 10 minutes  
**Actions**:
1. 在 IdeaBox/ 下创建 Authentication/ Group
2. 创建子 Groups: Models/, Services/, ViewModels/, Views/
3. 在 Views/ 下创建 Components/ Group
4. 在 IdeaBoxTests/ 下创建 Authentication/ Group
5. 创建子 Groups: Services/, ViewModels/, Integration/

**Acceptance Criteria**:
- 所有文件夹已创建
- 文件夹结构与 plan.md 一致

**Dependency**: After T003

---

## Phase 3.2: Models (Data Layer) (7 tasks, ~3 hours)

**NOTE**: 这些任务可以并行执行 [P]，因为它们创建不同的文件且无依赖关系。

### T005: [P] 实现 User Model
**Description**: 创建用户数据模型  
**File**: `IdeaBox/Authentication/Models/User.swift`  
**Time**: 30 minutes  
**Actions**:
- 根据 data-model.md 实现 User struct
- 包含所有字段：id, email, displayName, photoURL, createdAt, lastLoginAt, emailVerified, authMethod, rememberMe, theme, language
- 实现 Identifiable, Codable, Equatable protocols
- 添加 computed properties: isEmailVerified, initials
- 实现 Firebase User 初始化器：`init(from firebaseUser: FirebaseAuth.User)`

**Acceptance Criteria**:
- User.swift 编译无错误
- 所有字段已定义
- Protocols 已实现
- Firebase 映射已实现

**Dependency**: After T004

---

### T006: [P] 实现 UserSession Model
**Description**: 创建用户会话数据模型  
**File**: `IdeaBox/Authentication/Models/UserSession.swift`  
**Time**: 20 minutes  
**Actions**:
- 根据 data-model.md 实现 UserSession struct
- 包含字段：sessionId, user, token, refreshToken, createdAt, expiresAt, rememberMe, deviceId, deviceName, lastActivityAt
- 实现 Codable, Equatable protocols
- 添加 computed properties: isExpired, isActive, sessionDuration

**Acceptance Criteria**:
- UserSession.swift 编译无错误
- 所有字段和 computed properties 已定义
- Protocols 已实现

**Dependency**: After T005 (depends on User model)

---

### T007: [P] 实现 AuthenticationMethod Enum
**Description**: 创建认证方式枚举  
**File**: `IdeaBox/Authentication/Models/AuthenticationMethod.swift`  
**Time**: 10 minutes  
**Actions**:
- 实现 AuthenticationMethod enum (email, apple)
- 实现 Codable, CaseIterable protocols
- 添加 displayName 和 icon computed properties

**Acceptance Criteria**:
- AuthenticationMethod.swift 编译无错误
- 枚举包含 email 和 apple cases
- Display properties 已实现

**Dependency**: After T004

---

### T008: [P] 实现 AuthError Enum
**Description**: 创建自定义认证错误类型  
**File**: `IdeaBox/Authentication/Models/AuthError.swift`  
**Time**: 30 minutes  
**Actions**:
- 根据 data-model.md 实现 AuthError enum
- 包含所有错误 cases（invalidEmail, weakPassword, emailAlreadyInUse, etc.）
- 实现 LocalizedError, Equatable protocols
- 实现 errorDescription 和 recoverySuggestion properties
- 实现 `static func map(from error: Error) -> AuthError` 方法（Firebase 错误映射）

**Acceptance Criteria**:
- AuthError.swift 编译无错误
- 所有错误 cases 已定义
- 用户友好的错误消息（中文）
- Firebase 错误映射已实现

**Dependency**: After T004

---

### T009: [P] 实现 ValidationError Enum
**Description**: 创建输入验证错误类型  
**File**: `IdeaBox/Authentication/Models/ValidationError.swift`  
**Time**: 15 minutes  
**Actions**:
- 实现 ValidationError enum
- 包含 cases: invalidEmailFormat, passwordTooShort, passwordNoLetters, passwordNoNumbers, commonPassword, passwordMismatch, emptyField
- 实现 LocalizedError, Equatable protocols
- 实现错误描述和恢复建议

**Acceptance Criteria**:
- ValidationError.swift 编译无错误
- 所有 validation errors 已定义
- 错误消息中文化

**Dependency**: After T004

---

### T010: [P] 实现 PasswordStrength Enum
**Description**: 创建密码强度评估枚举  
**File**: `IdeaBox/Authentication/Models/PasswordStrength.swift`  
**Time**: 15 minutes  
**Actions**:
- 实现 PasswordStrength enum (weak, medium, strong)
- 实现 Comparable protocol
- 添加 displayName 和 color properties

**Acceptance Criteria**:
- PasswordStrength.swift 编译无错误
- 枚举可以比较
- UI 属性已定义

**Dependency**: After T004

---

### T011: [P] 实现 AppTheme Enum
**Description**: 创建应用主题枚举  
**File**: `IdeaBox/Authentication/Models/AppTheme.swift`  
**Time**: 10 minutes  
**Actions**:
- 实现 AppTheme enum (light, dark, system)
- 实现 Codable, CaseIterable protocols
- 添加 displayName 和 colorScheme properties

**Acceptance Criteria**:
- AppTheme.swift 编译无错误
- 主题选项已定义
- SwiftUI ColorScheme 映射已实现

**Dependency**: After T004

---

## Phase 3.3: Service Protocols (3 tasks, ~1 hour)

**NOTE**: 这些任务可以并行执行 [P]。

### T012: [P] 定义 AuthenticationServiceProtocol
**Description**: 创建认证服务接口  
**File**: `IdeaBox/Authentication/Services/AuthenticationServiceProtocol.swift`  
**Time**: 20 minutes  
**Actions**:
- 根据 contracts/AuthenticationService.md 定义 protocol
- 包含方法：signUp, sendEmailVerification, signIn, signOut, sendPasswordReset, currentUser, reloadUser, isEmailVerified
- 定义 authStatePublisher: AnyPublisher<User?, Never>
- 添加完整的文档注释

**Acceptance Criteria**:
- Protocol 已定义，编译无错误
- 所有方法签名与 contract 一致
- 包含详细的文档注释

**Dependency**: After T005, T008

---

### T013: [P] 定义 UserSessionManagerProtocol
**Description**: 创建会话管理服务接口  
**File**: `IdeaBox/Authentication/Services/UserSessionManagerProtocol.swift`  
**Time**: 20 minutes  
**Actions**:
- 根据 contracts/UserSessionManager.md 定义 protocol
- 包含属性：isAuthenticated, currentUser, sessionPublisher
- 包含方法：startSession, endSession, refreshSession, loadPersistedSession, clearPersistedSession, isSessionValid, timeUntilExpiry
- 添加完整的文档注释

**Acceptance Criteria**:
- Protocol 已定义，编译无错误
- 所有方法签名与 contract 一致
- 包含详细的文档注释

**Dependency**: After T005, T006, T008

---

### T014: [P] 定义 ValidationServiceProtocol
**Description**: 创建验证服务接口  
**File**: `IdeaBox/Authentication/Services/ValidationServiceProtocol.swift`  
**Time**: 20 minutes  
**Actions**:
- 根据 contracts/ValidationService.md 定义 protocol
- 包含方法：validateEmail, isValidEmail, validatePassword, calculatePasswordStrength, isCommonPassword, validateNotEmpty, validateSignUpForm, validateSignInForm
- 添加完整的文档注释

**Acceptance Criteria**:
- Protocol 已定义，编译无错误
- 所有方法签名与 contract 一致
- 包含详细的文档注释

**Dependency**: After T009, T010

---

## Phase 3.4: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.5

**CRITICAL**: 这些测试必须先编写，并且必须失败，然后才能实现功能代码。

### T015: [P] ValidationService 单元测试
**Description**: 编写验证服务的单元测试（测试优先）  
**File**: `IdeaBoxTests/Authentication/Services/ValidationServiceTests.swift`  
**Time**: 60 minutes  
**Actions**:
- 创建 ValidationServiceTests 测试类
- 编写测试用例：
  - `testValidateEmailWithValidFormat()` - 有效邮箱
  - `testValidateEmailWithInvalidFormat()` - 无效邮箱
  - `testValidatePasswordWithValidPassword()` - 有效密码
  - `testValidatePasswordWithWeakPassword()` - 弱密码
  - `testCalculatePasswordStrength()` - 密码强度计算
  - `testIsCommonPassword()` - 常见密码检测
  - `testValidateSignUpForm()` - 注册表单验证
  - `testValidateSignInForm()` - 登录表单验证
- 运行测试，确认全部失败（红色）

**Acceptance Criteria**:
- 测试文件已创建
- 至少 8 个测试用例
- 所有测试运行并失败（因为实现不存在）
- 测试代码清晰易懂

**Dependency**: After T014

---

### T016: [P] AuthenticationService 单元测试
**Description**: 编写认证服务的单元测试（测试优先）  
**File**: `IdeaBoxTests/Authentication/Services/AuthenticationServiceTests.swift`  
**Time**: 60 minutes  
**Actions**:
- 创建 AuthenticationServiceTests 测试类
- 编写测试用例：
  - `testSignUpCreatesNewUser()` - 注册创建用户
  - `testSignUpSendsVerificationEmail()` - 发送验证邮件
  - `testSignInWithValidCredentials()` - 有效凭据登录
  - `testSignInWithInvalidCredentials()` - 无效凭据登录
  - `testSignOutClearsCurrentUser()` - 登出清除用户
  - `testSendPasswordResetEmail()` - 密码重置
  - `testAuthStatePublisher()` - 状态变化推送
- 使用 Firebase Auth Emulator 或 Mock
- 运行测试，确认全部失败（红色）

**Acceptance Criteria**:
- 测试文件已创建
- 至少 7 个测试用例
- 所有测试运行并失败
- Mock 或 Emulator 配置正确

**Dependency**: After T012

---

### T017: [P] UserSessionManager 单元测试
**Description**: 编写会话管理器的单元测试（测试优先）  
**File**: `IdeaBoxTests/Authentication/Services/UserSessionManagerTests.swift`  
**Time**: 60 minutes  
**Actions**:
- 创建 UserSessionManagerTests 测试类
- 编写测试用例：
  - `testStartSessionCreatesValidSession()` - 创建会话
  - `testStartSessionPersistsToKeychain()` - 持久化存储
  - `testEndSessionClearsSessionData()` - 清除会话
  - `testLoadPersistedSessionRestoresSession()` - 恢复会话
  - `testSessionExpiryInvalidatesSession()` - 会话过期
  - `testRefreshSessionUpdatesToken()` - 刷新 token
  - `testSessionPublisher()` - 会话状态推送
- Mock Keychain 和 UserDefaults
- 运行测试，确认全部失败（红色）

**Acceptance Criteria**:
- 测试文件已创建
- 至少 7 个测试用例
- 所有测试运行并失败
- Mock 依赖已配置

**Dependency**: After T013

---

### T018: [P] 邮箱注册集成测试
**Description**: 编写邮箱注册的端到端集成测试  
**File**: `IdeaBoxTests/Authentication/Integration/EmailSignUpFlowTests.swift`  
**Time**: 30 minutes  
**Actions**:
- 创建集成测试类
- 测试完整注册流程：
  1. 用户输入邮箱和密码
  2. 调用 signUp
  3. 验证用户已创建
  4. 验证邮件已发送
  5. 验证会话已创建
- 使用真实的 Firebase 或 Emulator
- 运行测试，确认失败

**Acceptance Criteria**:
- 集成测试已创建
- 测试覆盖完整注册流程
- 测试运行并失败

**Dependency**: After T012, T013

---

### T019: [P] 邮箱登录集成测试
**Description**: 编写邮箱登录的端到端集成测试  
**File**: `IdeaBoxTests/Authentication/Integration/EmailLoginFlowTests.swift`  
**Time**: 30 minutes  
**Actions**:
- 创建集成测试类
- 测试完整登录流程：
  1. 用户输入邮箱和密码
  2. 调用 signIn
  3. 验证用户已认证
  4. 验证会话已创建
  5. 验证数据已同步
- 运行测试，确认失败

**Acceptance Criteria**:
- 集成测试已创建
- 测试覆盖完整登录流程
- 测试运行并失败

**Dependency**: After T012, T013

---

### T020: [P] 密码重置集成测试
**Description**: 编写密码重置的端到端集成测试  
**File**: `IdeaBoxTests/Authentication/Integration/PasswordResetFlowTests.swift`  
**Time**: 20 minutes  
**Actions**:
- 创建集成测试类
- 测试密码重置流程：
  1. 用户请求密码重置
  2. 调用 sendPasswordReset
  3. 验证邮件已发送
- 运行测试，确认失败

**Acceptance Criteria**:
- 集成测试已创建
- 测试覆盖重置流程
- 测试运行并失败

**Dependency**: After T012

---

### T021: [P] 会话持久化集成测试
**Description**: 编写会话持久化的集成测试  
**File**: `IdeaBoxTests/Authentication/Integration/SessionPersistenceTests.swift`  
**Time**: 30 minutes  
**Actions**:
- 创建集成测试类
- 测试会话持久化：
  1. 用户登录
  2. 应用重启（模拟）
  3. 验证会话已恢复
  4. 验证用户仍然已登录
- 运行测试，确认失败

**Acceptance Criteria**:
- 集成测试已创建
- 测试覆盖持久化流程
- 测试运行并失败

**Dependency**: After T013

---

## Phase 3.5: Service Implementation (3 tasks, ~4 hours)

**CRITICAL**: 只有在所有测试编写完成并失败后才能开始实现。

### T022: 实现 ValidationService
**Description**: 实现验证服务（让测试变绿）  
**File**: `IdeaBox/Authentication/Services/ValidationService.swift`  
**Time**: 90 minutes  
**Actions**:
- 创建 ValidationService 类，遵循 ValidationServiceProtocol
- 实现所有验证方法：
  - validateEmail（使用正则表达式）
  - validatePassword（检查长度、字母、数字）
  - calculatePasswordStrength（根据规则计算分数）
  - isCommonPassword（检查常见密码列表）
  - validateSignUpForm / validateSignInForm
- 添加常见密码列表（从 SecLists 获取 top 10k）
- 运行测试，确保全部通过（绿色）

**Acceptance Criteria**:
- ValidationService.swift 已实现
- 所有 protocol 方法已实现
- T015 的所有测试通过 ✅
- 代码经过重构，无重复

**Dependency**: After T015 (tests must fail first)

---

### T023: 实现 AuthenticationService
**Description**: 实现认证服务（让测试变绿）  
**File**: `IdeaBox/Authentication/Services/AuthenticationService.swift`  
**Time**: 120 minutes  
**Actions**:
- 创建 FirebaseAuthenticationService 类，遵循 AuthenticationServiceProtocol
- 集成 Firebase Auth
- 实现所有认证方法：
  - signUp：使用 `Auth.auth().createUser()`，包装为 async/await
  - signIn：使用 `Auth.auth().signIn()`
  - signOut：使用 `Auth.auth().signOut()`
  - sendEmailVerification / sendPasswordReset
  - currentUser：从 Firebase 获取当前用户
  - authStatePublisher：使用 Combine 包装 Firebase auth state listener
- 错误映射：Firebase 错误 → AuthError
- 运行测试，确保 T016, T018, T019, T020 通过

**Acceptance Criteria**:
- AuthenticationService.swift 已实现
- Firebase Auth 集成正确
- 所有 protocol 方法已实现
- T016, T018, T019, T020 测试通过 ✅
- async/await 包装正确

**Dependency**: After T016, T018, T019, T020 (tests must fail first)

---

### T024: 实现 UserSessionManager
**Description**: 实现会话管理器（让测试变绿）  
**File**: `IdeaBox/Authentication/Services/UserSessionManager.swift`  
**Time**: 120 minutes  
**Actions**:
- 创建 UserSessionManager 类，遵循 UserSessionManagerProtocol
- 集成 KeychainAccess 库（SPM 添加）
- 实现会话管理方法：
  - startSession：存储到 Keychain + UserDefaults
  - endSession：清除所有存储
  - loadPersistedSession：从 Keychain 恢复
  - refreshSession：更新 token
  - sessionPublisher：Combine publisher
- Keychain keys: userId, authToken, sessionId
- UserDefaults keys: sessionExpiresAt, rememberMe, lastActivityAt
- 运行测试，确保 T017, T021 通过

**Acceptance Criteria**:
- UserSessionManager.swift 已实现
- Keychain 集成正确
- 所有 protocol 方法已实现
- T017, T021 测试通过 ✅
- 会话持久化工作正常

**Dependency**: After T017, T021 (tests must fail first)

---

## Phase 3.6: ViewModels (3 tasks, ~3 hours)

### T025: [P] 实现 LoginViewModel
**Description**: 实现登录界面的 ViewModel  
**File**: `IdeaBox/Authentication/ViewModels/LoginViewModel.swift`  
**Time**: 60 minutes  
**Actions**:
- 创建 LoginViewModel 类（ObservableObject）
- 属性：email, password, errorMessage, isLoading
- 依赖注入：AuthenticationService, ValidationService, UserSessionManager
- 实现方法：
  - `signIn()` - 验证输入 → 调用认证服务 → 创建会话
  - `validateInputs()` - 实时验证
  - `handleError()` - 错误处理和用户友好消息
- 使用 @Published 属性绑定 UI

**Acceptance Criteria**:
- LoginViewModel.swift 已创建
- 所有业务逻辑已实现
- 依赖注入正确
- 与 Services 集成

**Dependency**: After T022, T023, T024

---

### T026: [P] 实现 SignUpViewModel
**Description**: 实现注册界面的 ViewModel  
**File**: `IdeaBox/Authentication/ViewModels/SignUpViewModel.swift`  
**Time**: 60 minutes  
**Actions**:
- 创建 SignUpViewModel 类（ObservableObject）
- 属性：email, password, confirmPassword, errorMessage, isLoading, passwordStrength
- 依赖注入：AuthenticationService, ValidationService, UserSessionManager
- 实现方法：
  - `signUp()` - 验证 → 注册 → 发送验证邮件
  - `validateForm()` - 表单验证
  - `checkPasswordStrength()` - 实时密码强度
  - `handleError()` - 错误处理
- 密码强度实时更新

**Acceptance Criteria**:
- SignUpViewModel.swift 已创建
- 注册流程已实现
- 密码强度计算已集成
- 表单验证正确

**Dependency**: After T022, T023, T024

---

### T027: [P] 实现 ForgotPasswordViewModel
**Description**: 实现忘记密码界面的 ViewModel  
**File**: `IdeaBox/Authentication/ViewModels/ForgotPasswordViewModel.swift`  
**Time**: 30 minutes  
**Actions**:
- 创建 ForgotPasswordViewModel 类（ObservableObject）
- 属性：email, successMessage, errorMessage, isLoading
- 依赖注入：AuthenticationService, ValidationService
- 实现方法：
  - `sendResetEmail()` - 验证邮箱 → 发送重置邮件
  - `validateEmail()` - 邮箱验证
  - `handleError()` - 错误处理

**Acceptance Criteria**:
- ForgotPasswordViewModel.swift 已创建
- 密码重置流程已实现
- 邮箱验证已集成

**Dependency**: After T022, T023

---

## Phase 3.7: Views (UI Components) (8 tasks, ~5 hours)

**NOTE**: Components (T028-T031) 可以并行执行 [P]。

### T028: [P] 实现 EmailTextField 组件
**Description**: 创建可复用的邮箱输入框组件  
**File**: `IdeaBox/Authentication/Views/Components/EmailTextField.swift`  
**Time**: 30 minutes  
**Actions**:
- 创建 EmailTextField SwiftUI View
- 特性：
  - 邮箱图标
  - Placeholder "邮箱"
  - 自动小写
  - 自动关闭首字母大写
  - 实时验证提示（可选）
  - 暗黑模式支持
- 样式与 Figma 设计一致

**Acceptance Criteria**:
- EmailTextField.swift 已创建
- 组件可复用
- 样式美观
- 支持暗黑模式

**Dependency**: After T004

---

### T029: [P] 实现 PasswordTextField 组件
**Description**: 创建可复用的密码输入框组件  
**File**: `IdeaBox/Authentication/Views/Components/PasswordTextField.swift`  
**Time**: 40 minutes  
**Actions**:
- 创建 PasswordTextField SwiftUI View
- 特性：
  - 密码图标
  - Placeholder "密码"
  - 显示/隐藏密码按钮
  - SecureField / TextField 切换
  - 密码强度指示器（可选）
  - 暗黑模式支持
- 样式与 Figma 设计一致

**Acceptance Criteria**:
- PasswordTextField.swift 已创建
- 显示/隐藏功能工作正常
- 组件可复用
- 支持暗黑模式

**Dependency**: After T004

---

### T030: [P] 实现 AuthButton 组件
**Description**: 创建认证按钮组件  
**File**: `IdeaBox/Authentication/Views/Components/AuthButton.swift`  
**Time**: 20 minutes  
**Actions**:
- 创建 AuthButton SwiftUI View
- 特性：
  - 主要操作按钮样式
  - 加载状态（显示 ProgressView）
  - 禁用状态
  - 自定义文本和操作
  - 暗黑模式支持
- 符合 iOS 设计规范

**Acceptance Criteria**:
- AuthButton.swift 已创建
- 加载和禁用状态正确
- 样式美观
- 可复用

**Dependency**: After T004

---

### T031: [P] 实现 AuthErrorView 组件
**Description**: 创建错误消息显示组件  
**File**: `IdeaBox/Authentication/Views/Components/AuthErrorView.swift`  
**Time**: 20 minutes  
**Actions**:
- 创建 AuthErrorView SwiftUI View
- 特性：
  - 错误图标
  - 错误消息文本
  - 恢复建议（可选）
  - 关闭按钮
  - 暗黑模式支持
- Banner 或 Alert 样式

**Acceptance Criteria**:
- AuthErrorView.swift 已创建
- 错误显示清晰
- 样式友好
- 可复用

**Dependency**: After T004

---

### T032: 实现 LoginView
**Description**: 创建登录界面  
**File**: `IdeaBox/Authentication/Views/LoginView.swift`  
**Time**: 60 minutes  
**Actions**:
- 创建 LoginView SwiftUI View
- 布局：
  - Logo/标题
  - EmailTextField
  - PasswordTextField
  - 忘记密码链接
  - 登录按钮（AuthButton）
  - 注册链接
  - 错误显示（AuthErrorView）
- 集成 LoginViewModel
- Binding：email, password, errorMessage, isLoading
- 导航：跳转到 SignUpView, ForgotPasswordView

**Acceptance Criteria**:
- LoginView.swift 已创建
- UI 布局正确
- ViewModel 集成
- 导航工作正常
- 暗黑模式支持

**Dependency**: After T025, T028, T029, T030, T031

---

### T033: 实现 SignUpView
**Description**: 创建注册界面  
**File**: `IdeaBox/Authentication/Views/SignUpView.swift`  
**Time**: 60 minutes  
**Actions**:
- 创建 SignUpView SwiftUI View
- 布局：
  - Logo/标题
  - EmailTextField
  - PasswordTextField
  - 确认密码 PasswordTextField
  - 密码强度指示器
  - 注册按钮（AuthButton）
  - 返回登录链接
  - 错误显示（AuthErrorView）
- 集成 SignUpViewModel
- Binding：email, password, confirmPassword, passwordStrength, errorMessage, isLoading
- 成功后提示检查邮件

**Acceptance Criteria**:
- SignUpView.swift 已创建
- UI 布局正确
- ViewModel 集成
- 密码强度显示
- 暗黑模式支持

**Dependency**: After T026, T028, T029, T030, T031

---

### T034: 实现 ForgotPasswordView
**Description**: 创建忘记密码界面  
**File**: `IdeaBox/Authentication/Views/ForgotPasswordView.swift`  
**Time**: 40 minutes  
**Actions**:
- 创建 ForgotPasswordView SwiftUI View
- 布局：
  - 说明文本
  - EmailTextField
  - 发送重置邮件按钮（AuthButton）
  - 返回登录链接
  - 成功/错误消息显示
- 集成 ForgotPasswordViewModel
- Binding：email, successMessage, errorMessage, isLoading
- 成功后显示确认消息

**Acceptance Criteria**:
- ForgotPasswordView.swift 已创建
- UI 布局正确
- ViewModel 集成
- 成功消息显示
- 暗黑模式支持

**Dependency**: After T027, T028, T030, T031

---

### T035: 实现 AuthenticationView (Coordinator)
**Description**: 创建认证流程协调器  
**File**: `IdeaBox/Authentication/Views/AuthenticationView.swift`  
**Time**: 30 minutes  
**Actions**:
- 创建 AuthenticationView SwiftUI View
- 职责：管理登录流程的导航
- 包含：
  - NavigationStack/NavigationView
  - 默认显示 LoginView
  - 导航到 SignUpView
  - 导航到 ForgotPasswordView
- 监听认证状态，成功后自动关闭

**Acceptance Criteria**:
- AuthenticationView.swift 已创建
- 导航流程正确
- 认证成功后自动关闭
- 作为主入口点

**Dependency**: After T032, T033, T034

---

## Phase 3.8: Integration (App Integration) (2 tasks, ~1 hour)

### T036: 更新 IdeaBoxApp 添加认证状态检查
**Description**: 在应用启动时检查认证状态  
**File**: `IdeaBox/IdeaBoxApp.swift`  
**Time**: 30 minutes  
**Actions**:
- 在 App init() 中：
  1. FirebaseApp.configure() (已有)
  2. 创建 UserSessionManager 实例
  3. 调用 loadPersistedSession()
- 创建 @StateObject 或 @EnvironmentObject 管理全局认证状态
- 根据 isAuthenticated 决定显示哪个界面

**Code Structure**:
```swift
@main
struct IdeaBoxApp: App {
    @StateObject private var authState = AuthenticationStateManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authState.isAuthenticated {
                ContentView()
            } else {
                AuthenticationView()
            }
        }
    }
}
```

**Acceptance Criteria**:
- IdeaBoxApp.swift 已更新
- 认证状态管理已实现
- 启动时检查登录状态
- 根据状态显示正确界面

**Dependency**: After T024, T035

---

### T037: 更新 ContentView 添加登出功能
**Description**: 在主界面添加登出选项  
**File**: `IdeaBox/ContentView.swift`  
**Time**: 30 minutes  
**Actions**:
- 在设置或导航栏添加"退出登录"按钮
- 集成 AuthenticationService.signOut()
- 集成 UserSessionManager.endSession()
- 成功登出后返回登录界面
- 添加确认对话框（Alert）

**Acceptance Criteria**:
- ContentView.swift 已更新
- 登出按钮已添加
- 登出功能正常工作
- 数据清理正确

**Dependency**: After T023, T024, T036

---

## Phase 3.9: Polish & Documentation (3 tasks, ~2 hours)

### T038: [P] 添加 VoiceOver 支持
**Description**: 为所有认证界面添加辅助功能标签  
**Files**: All Views in `IdeaBox/Authentication/Views/`  
**Time**: 40 minutes  
**Actions**:
- 为所有输入框添加 `.accessibilityLabel`
- 为所有按钮添加 `.accessibilityHint`
- 为错误消息添加 `.accessibilityLiveRegion`
- 测试 VoiceOver 导航流程
- 确保键盘导航正确

**Acceptance Criteria**:
- 所有 Views 有辅助功能标签
- VoiceOver 可以正确读取
- 键盘导航流畅
- 符合 iOS 辅助功能最佳实践

**Dependency**: After T032, T033, T034, T035

---

### T039: [P] 性能测试和优化
**Description**: 测试登录流程性能并优化  
**Files**: Performance tests in `IdeaBoxTests/Authentication/`  
**Time**: 40 minutes  
**Actions**:
- 测量登录流程端到端时间
- 目标：< 3 秒（网络正常）
- 测量 UI 响应时间
- 目标：< 500ms
- 测量内存占用
- 目标：< 50MB 增量
- 优化慢的部分
- 添加性能基准测试

**Acceptance Criteria**:
- 性能测试已编写
- 所有性能目标达成
- 无明显卡顿或延迟
- 内存使用合理

**Dependency**: After T036, T037

---

### T040: [P] 更新文档和注释
**Description**: 完善代码文档和 API 注释  
**Files**: All Swift files in `IdeaBox/Authentication/`  
**Time**: 40 minutes  
**Actions**:
- 为所有 public 类和方法添加文档注释
- 使用 Swift markup 格式（///）
- 包含参数说明、返回值、错误情况
- 更新 README 或项目文档
- 添加使用示例
- 确保 Xcode Quick Help 可用

**Acceptance Criteria**:
- 所有 public API 有文档注释
- 注释清晰准确
- Xcode Quick Help 显示正确
- 代码易于理解

**Dependency**: After T022, T023, T024

---

## Dependencies Graph

```
Setup (T001-T004)
    ↓
Models (T005-T011) [Parallel]
    ↓
Protocols (T012-T014) [Parallel]
    ↓
Tests (T015-T021) [Parallel] ⚠️ MUST FAIL
    ↓
Services (T022-T024) [Sequential, make tests pass]
    ↓
ViewModels (T025-T027) [Parallel]
    ↓
UI Components (T028-T031) [Parallel]
    ↓
Views (T032-T035) [Sequential]
    ↓
Integration (T036-T037) [Sequential]
    ↓
Polish (T038-T040) [Parallel]
```

**Critical Path**: T001 → T004 → T005 → T012 → T016 → T023 → T025 → T032 → T035 → T036

---

## Parallel Execution Examples

### Example 1: Models Phase (After T004)
```bash
# 可以同时启动 7 个任务：
T005: Create User.swift
T006: Create UserSession.swift
T007: Create AuthenticationMethod.swift
T008: Create AuthError.swift
T009: Create ValidationError.swift
T010: Create PasswordStrength.swift
T011: Create AppTheme.swift
```

### Example 2: Tests Phase (After T012-T014)
```bash
# 可以同时启动 7 个测试任务：
T015: ValidationServiceTests.swift
T016: AuthenticationServiceTests.swift
T017: UserSessionManagerTests.swift
T018: EmailSignUpFlowTests.swift
T019: EmailLoginFlowTests.swift
T020: PasswordResetFlowTests.swift
T021: SessionPersistenceTests.swift
```

### Example 3: UI Components (After T004, T025-T027)
```bash
# 可以同时启动 4 个组件任务：
T028: EmailTextField.swift
T029: PasswordTextField.swift
T030: AuthButton.swift
T031: AuthErrorView.swift
```

---

## Validation Checklist

### Task Completeness
- [x] All contracts have corresponding tests (T015-T021)
- [x] All entities have model tasks (T005-T011)
- [x] All tests come before implementation (Phase 3.4 before 3.5)
- [x] Parallel tasks truly independent (different files)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task

### TDD Compliance
- [x] Tests written before implementation
- [x] Tests fail initially (red)
- [x] Implementation makes tests pass (green)
- [x] Code refactored (refactor)

### Coverage
- [x] Unit tests for all services
- [x] Integration tests for user flows
- [x] UI tests not required (manual testing acceptable)
- [x] Performance tests included

---

## Notes

### Best Practices
- ✅ Commit after completing each task
- ✅ Run tests before committing
- ✅ Follow Swift naming conventions
- ✅ Use SwiftLint for code quality
- ✅ Write meaningful commit messages

### Common Pitfalls to Avoid
- ❌ Implementing before writing tests
- ❌ Skipping error handling
- ❌ Hardcoding strings (use localization)
- ❌ Ignoring memory leaks (use weak self)
- ❌ Poor naming (use descriptive names)

### Resources
- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [async/await Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)

---

## Estimated Timeline

| Phase | Tasks | Estimated Time | Parallel? |
|-------|-------|----------------|-----------|
| **Setup** | T001-T004 | 1 hour | Mostly sequential |
| **Models** | T005-T011 | 3 hours | ✅ Parallel |
| **Protocols** | T012-T014 | 1 hour | ✅ Parallel |
| **Tests** | T015-T021 | 5 hours | ✅ Parallel |
| **Services** | T022-T024 | 6 hours | Sequential |
| **ViewModels** | T025-T027 | 3 hours | ✅ Parallel |
| **UI** | T028-T035 | 5 hours | Mixed |
| **Integration** | T036-T037 | 1 hour | Sequential |
| **Polish** | T038-T040 | 2 hours | ✅ Parallel |
| **TOTAL** | 40 tasks | **27 hours** | |

**With Parallelization**: ~18-20 hours (2-3 days with single developer)

**With Multiple Developers**: ~12-15 hours (1.5-2 days with 2-3 developers)

---

## Summary

✅ **40 tasks generated**  
✅ **27 hours estimated** (18-20 hours with parallelization)  
✅ **TDD approach enforced** (tests before implementation)  
✅ **Clear dependencies** (can be executed in order)  
✅ **Parallel execution marked** ([P] for 21 tasks)  
✅ **File paths specified** (exact locations)  
✅ **Acceptance criteria defined** (clear success metrics)

---

**Status**: ✅ **Tasks Ready for Execution**

**Next Action**: Start with T001 (Firebase Project Configuration)

**Command**: Begin implementation following TDD principles

---

*Generated*: 2025-10-20  
*Based on*: plan.md, data-model.md, contracts/, research.md, quickstart.md  
*Ready for*: Phase 3 Implementation (TDD Development)

