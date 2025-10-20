# Implementation Plan: Firebase 邮箱登录系统 (Phase 1)

**Branch**: `010-apple-sign-in` | **Date**: 2025-10-20 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/010-apple-sign-in/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → ✅ Feature spec loaded successfully
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → ✅ All clarifications resolved in spec
   → ✅ Project Type: iOS mobile app (SwiftUI)
   → ✅ Structure Decision: iOS app structure
3. Fill the Constitution Check section
   → ✅ No constitution violations detected
4. Evaluate Constitution Check section
   → ✅ No complexity deviations needed
   → ✅ Progress Tracking: Initial Constitution Check PASS
5. Execute Phase 0 → research.md
   → ✅ Research tasks identified and documented
6. Execute Phase 1 → contracts, data-model.md, quickstart.md
   → ✅ All artifacts generated
7. Re-evaluate Constitution Check
   → ✅ Post-Design Constitution Check PASS
8. Plan Phase 2 → Task generation approach described
9. ✅ STOP - Ready for /tasks command
```

## Summary

**Primary Requirement**: 实现基于 Firebase Authentication 的邮箱/密码登录系统，为 IdeaBox 日历应用提供用户认证和会话管理功能。

**Technical Approach**: 
- 使用 Firebase iOS SDK 作为认证后端（BaaS 方案）
- SwiftUI 构建登录界面
- MVVM 架构分离业务逻辑
- Keychain 存储敏感数据
- UserDefaults 存储用户偏好设置
- 单元测试 + 集成测试覆盖核心认证流程

**Implementation Scope (Phase 1)**:
- ✅ 邮箱/密码注册和登录
- ✅ 邮箱验证流程
- ✅ 密码重置功能
- ✅ 会话管理（30/90天）
- ✅ 多设备支持
- ⏸️ Apple Sign In（Phase 2）

## Technical Context

**Language/Version**: Swift 5.9+ (Xcode 15.0+)  
**Primary Dependencies**: 
- Firebase iOS SDK 10.0+ (FirebaseAuth, FirebaseFirestore)
- SwiftUI (iOS 15.0+)
- Combine Framework (响应式编程)

**Storage**: 
- **Remote**: Firebase Authentication (用户账号)
- **Remote**: Firebase Firestore (用户数据和日历事件)
- **Local**: Keychain (认证令牌)
- **Local**: UserDefaults (用户偏好设置)

**Testing**: 
- XCTest (单元测试和集成测试)
- Firebase Auth Emulator (本地测试环境)

**Target Platform**: iOS 15.0+, iPhone and iPad  

**Project Type**: Mobile (iOS app)

**Performance Goals**: 
- 登录流程完成时间 < 3 秒
- UI 操作响应时间 < 500ms
- 内存占用增量 < 50MB
- 冷启动时间 < 2 秒

**Constraints**: 
- 必须支持离线登录状态检查（本地令牌验证）
- 必须支持暗黑模式
- 必须支持 VoiceOver 辅助功能
- 邮箱验证邮件送达率 > 95%
- Firebase 免费额度限制（月活 < 10,000 用户）

**Scale/Scope**: 
- 预期用户规模：100-1000 MAU (Phase 1)
- 5-8 个主要 UI 界面
- 约 15-20 个 Swift 文件
- 约 2000-3000 行代码（含测试）

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

由于项目的 constitution.md 尚未定制化，使用通用的 iOS 开发最佳实践作为指导原则：

**✅ PASS - 遵循的原则**:

1. **单一职责原则**: 每个 Service/Manager 类只负责一个领域
   - `AuthenticationService`: 只负责 Firebase 认证
   - `UserSessionManager`: 只负责会话状态管理
   - `ValidationService`: 只负责输入验证

2. **依赖注入**: 所有服务通过协议注入，便于测试
   - 使用 Protocol 定义接口
   - ViewModels 接收 Service 依赖
   - Mock 实现用于单元测试

3. **测试优先**: 
   - 核心认证流程编写集成测试
   - Service 层编写单元测试
   - UI 层编写快照测试（可选）

4. **错误处理**: 
   - 自定义 `AuthError` 枚举
   - 所有网络调用使用 `async/throws`
   - 友好的用户错误消息映射

5. **安全性**:
   - 敏感数据存储在 Keychain
   - 不在日志中打印密码
   - HTTPS 强制加密通信

**❌ 无违规项** - 不需要填写 Complexity Tracking

## Project Structure

### Documentation (this feature)
```
specs/010-apple-sign-in/
├── plan.md              # ✅ This file (/plan command output)
├── research.md          # ✅ Phase 0 output (technology decisions)
├── data-model.md        # ✅ Phase 1 output (entities and schemas)
├── quickstart.md        # ✅ Phase 1 output (setup and test guide)
├── contracts/           # ✅ Phase 1 output (service contracts)
│   ├── AuthenticationService.md
│   ├── UserSessionManager.md
│   └── ValidationService.md
└── tasks.md             # ⏸️ Phase 2 output (/tasks command)
```

### Source Code (repository root)
```
IdeaBox/                                 # iOS App Target
├── Authentication/                      # 🆕 Authentication Feature Module
│   ├── Models/
│   │   ├── User.swift                  # User entity
│   │   ├── AuthenticationMethod.swift  # Login method enum
│   │   └── AuthError.swift             # Custom error types
│   ├── Services/
│   │   ├── AuthenticationService.swift           # Firebase auth wrapper
│   │   ├── AuthenticationServiceProtocol.swift   # Service interface
│   │   ├── UserSessionManager.swift              # Session management
│   │   ├── UserSessionManagerProtocol.swift      # Session interface
│   │   ├── ValidationService.swift               # Input validation
│   │   └── ValidationServiceProtocol.swift       # Validation interface
│   ├── ViewModels/
│   │   ├── LoginViewModel.swift        # Login screen logic
│   │   ├── SignUpViewModel.swift       # Sign up screen logic
│   │   └── ForgotPasswordViewModel.swift # Password reset logic
│   └── Views/
│       ├── AuthenticationView.swift    # Root auth coordinator
│       ├── LoginView.swift             # Login screen
│       ├── SignUpView.swift            # Sign up screen
│       ├── ForgotPasswordView.swift    # Password reset screen
│       └── Components/
│           ├── EmailTextField.swift    # Reusable email input
│           ├── PasswordTextField.swift # Reusable password input
│           ├── AuthButton.swift        # Primary action button
│           └── AuthErrorView.swift     # Error display component
│
├── IdeaBoxApp.swift                    # 📝 Update: Add auth state check
├── ContentView.swift                   # 📝 Update: Conditional rendering
├── GoogleService-Info.plist            # ✅ Already exists
└── Info.plist                          # 📝 Update: URL schemes (if needed)

IdeaBoxTests/
├── Authentication/                     # 🆕 Authentication Tests
│   ├── Services/
│   │   ├── AuthenticationServiceTests.swift
│   │   ├── UserSessionManagerTests.swift
│   │   └── ValidationServiceTests.swift
│   ├── ViewModels/
│   │   ├── LoginViewModelTests.swift
│   │   ├── SignUpViewModelTests.swift
│   │   └── ForgotPasswordViewModelTests.swift
│   └── Integration/
│       ├── EmailSignUpFlowTests.swift  # End-to-end registration
│       ├── EmailLoginFlowTests.swift   # End-to-end login
│       └── SessionPersistenceTests.swift # Session management
```

**Structure Decision**: 

采用 **功能模块化 (Feature Module)** 结构，将认证相关的所有代码组织在 `IdeaBox/Authentication/` 目录下。

**理由**：
1. **清晰的边界**: 认证功能是一个独立的业务域
2. **易于扩展**: Phase 2 添加 Apple Sign In 时只需在同一模块内扩展
3. **便于测试**: 测试文件结构镜像源代码结构
4. **团队协作**: 多人开发时减少文件冲突
5. **代码复用**: 可以提取为独立 Framework（未来考虑）

**架构模式**: MVVM (Model-View-ViewModel)
- **Models**: 数据实体（User, AuthError）
- **Services**: 业务逻辑和外部集成（Firebase）
- **ViewModels**: 视图逻辑和状态管理
- **Views**: SwiftUI 界面组件

## Phase 0: Outline & Research

### Research Tasks Identified

从 Technical Context 中提取的研究任务：

1. **Firebase iOS SDK 集成最佳实践**
   - 依赖管理方式选择（SPM vs CocoaPods）
   - 初始化配置最佳时机
   - 错误处理模式

2. **Firebase Authentication 邮箱验证流程**
   - `ActionCodeSettings` 配置
   - 验证邮件自定义
   - Deep linking 处理

3. **SwiftUI + Firebase 响应式集成**
   - Combine 与 Firebase 回调的桥接
   - `@Published` 属性的正确使用
   - 异步操作的 UI 状态管理

4. **iOS Keychain 安全存储**
   - Firebase token 的 Keychain 存储
   - 背景刷新时的 token 更新
   - Keychain 访问控制策略

5. **邮箱和密码验证规则**
   - RFC 5322 邮箱格式验证
   - 密码强度验证（OWASP 标准）
   - 实时验证 UX 最佳实践

6. **会话管理策略**
   - Firebase token 生命周期
   - 自动刷新机制
   - 离线状态处理

7. **多设备登录同步**
   - Firestore 实时监听
   - 冲突解决策略
   - 设备列表管理（可选）

### Research Output

**Output**: `research.md` 文件包含以下决策记录：

- **Decision 1**: 使用 Swift Package Manager (SPM) 集成 Firebase
- **Decision 2**: 在 `App.init()` 配置 Firebase
- **Decision 3**: 使用 `async/await` 包装 Firebase 回调
- **Decision 4**: 使用 `KeychainSwift` 库简化 Keychain 操作
- **Decision 5**: 采用 Firebase 默认邮箱验证流程
- **Decision 6**: 实时验证 + 提交验证双重检查
- **Decision 7**: 使用 Firebase 自动 token 刷新机制

详见 [research.md](./research.md)

## Phase 1: Design & Contracts

### 1. Data Model

**Output**: `data-model.md`

核心实体：

#### Entity: User
```swift
struct User: Identifiable, Codable {
    let id: String                    // Firebase UID
    let email: String
    var displayName: String?
    var photoURL: URL?
    let createdAt: Date
    var emailVerified: Bool
    let authMethod: AuthenticationMethod
}
```

#### Entity: UserSession
```swift
struct UserSession {
    let user: User
    let token: String
    let expiresAt: Date
    let rememberMe: Bool
}
```

#### Entity: AuthenticationMethod
```swift
enum AuthenticationMethod: String, Codable {
    case email
    case apple  // Phase 2
}
```

#### Entity: AuthError
```swift
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case networkError
    case tooManyRequests
    case emailNotVerified
    case unknown(Error)
    
    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

详见 [data-model.md](./data-model.md)

### 2. Service Contracts

**Output**: `contracts/` 目录

#### Contract 1: AuthenticationService

```swift
protocol AuthenticationServiceProtocol {
    // Sign Up
    func signUp(email: String, password: String) async throws -> User
    func sendEmailVerification() async throws
    
    // Sign In
    func signIn(email: String, password: String) async throws -> User
    func signOut() throws
    
    // Password Reset
    func sendPasswordReset(email: String) async throws
    
    // Current User
    func currentUser() -> User?
    var authStatePublisher: AnyPublisher<User?, Never> { get }
}
```

#### Contract 2: UserSessionManager

```swift
protocol UserSessionManagerProtocol {
    // Session State
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    var sessionPublisher: AnyPublisher<UserSession?, Never> { get }
    
    // Session Management
    func startSession(user: User, rememberMe: Bool) async throws
    func endSession() async throws
    func refreshSession() async throws
    
    // Session Persistence
    func loadPersistedSession() async -> UserSession?
    func clearPersistedSession() async throws
}
```

#### Contract 3: ValidationService

```swift
protocol ValidationServiceProtocol {
    // Email Validation
    func validateEmail(_ email: String) -> Result<Void, ValidationError>
    
    // Password Validation  
    func validatePassword(_ password: String) -> Result<Void, ValidationError>
    func validatePasswordStrength(_ password: String) -> PasswordStrength
    
    // Common Weak Passwords
    func isCommonPassword(_ password: String) -> Bool
}

enum ValidationError: LocalizedError {
    case invalidEmailFormat
    case passwordTooShort
    case passwordNoLetters
    case passwordNoNumbers
    case commonPassword
}

enum PasswordStrength {
    case weak, medium, strong
}
```

详见 `contracts/AuthenticationService.md`, `contracts/UserSessionManager.md`, `contracts/ValidationService.md`

### 3. Integration Test Scenarios

From user stories → Integration tests:

#### Test Scenario 1: 邮箱注册完整流程
```swift
func testEmailSignUpFlow() async throws {
    // Given: 新用户打开应用
    let email = "test@example.com"
    let password = "SecurePass123"
    
    // When: 用户完成注册流程
    let user = try await authService.signUp(email: email, password: password)
    
    // Then: 账号创建成功
    XCTAssertNotNil(user.id)
    XCTAssertEqual(user.email, email)
    XCTAssertEqual(user.authMethod, .email)
    
    // And: 验证邮件已发送
    XCTAssertFalse(user.emailVerified)
    
    // And: 会话已启动
    let session = await sessionManager.loadPersistedSession()
    XCTAssertNotNil(session)
}
```

#### Test Scenario 2: 邮箱登录流程
```swift
func testEmailLoginFlow() async throws {
    // Given: 已注册用户
    let email = "existing@example.com"
    let password = "SecurePass123"
    
    // When: 用户输入正确凭据
    let user = try await authService.signIn(email: email, password: password)
    
    // Then: 登录成功
    XCTAssertNotNil(user.id)
    XCTAssertEqual(user.email, email)
    
    // And: 会话已创建
    XCTAssertTrue(sessionManager.isAuthenticated)
    XCTAssertEqual(sessionManager.currentUser?.id, user.id)
}
```

#### Test Scenario 3: 密码重置流程
```swift
func testPasswordResetFlow() async throws {
    // Given: 用户忘记密码
    let email = "forgetful@example.com"
    
    // When: 用户请求密码重置
    try await authService.sendPasswordReset(email: email)
    
    // Then: 重置邮件已发送（Firebase 处理）
    // Note: 实际验证需要邮件接收测试
}
```

#### Test Scenario 4: 会话持久化
```swift
func testSessionPersistence() async throws {
    // Given: 用户已登录
    let user = try await authService.signIn(email: "test@example.com", password: "Pass123")
    try await sessionManager.startSession(user: user, rememberMe: true)
    
    // When: 应用重启（模拟）
    let persistedSession = await sessionManager.loadPersistedSession()
    
    // Then: 会话已恢复
    XCTAssertNotNil(persistedSession)
    XCTAssertEqual(persistedSession?.user.id, user.id)
}
```

### 4. Quickstart

**Output**: `quickstart.md`

包含：
1. Firebase 项目配置步骤
2. 依赖安装指南（SPM）
3. GoogleService-Info.plist 配置
4. 本地测试环境搭建
5. 首次运行检查清单
6. 常见问题排查

详见 [quickstart.md](./quickstart.md)

### 5. Agent Context Update

执行更新命令：

```bash
.specify/scripts/bash/update-agent-context.sh cursor
```

**Expected Changes**:
- 添加 Firebase Authentication 技术栈
- 添加 SwiftUI + Combine 模式
- 更新项目结构（Authentication 模块）
- 添加测试策略说明
- 保留手动添加的其他上下文

**Output**: Repository root `.cursorrules` 或 `.cursor/rules` 文件更新

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

### Task Generation Strategy

从 Phase 1 的设计文档生成任务：

#### 1. 基础设施任务 (Infrastructure)
- [ ] Task 1: 配置 Firebase 项目并下载 GoogleService-Info.plist
- [ ] Task 2: 添加 Firebase iOS SDK 依赖（SPM）
- [ ] Task 3: 在 IdeaBoxApp.swift 初始化 Firebase
- [ ] Task 4: 创建 Authentication 模块文件夹结构

#### 2. Models 任务 (Data Layer)
- [ ] Task 5: 实现 User model [P]
- [ ] Task 6: 实现 UserSession model [P]
- [ ] Task 7: 实现 AuthenticationMethod enum [P]
- [ ] Task 8: 实现 AuthError enum [P]

#### 3. Service Contracts 任务 (Protocols First)
- [ ] Task 9: 定义 AuthenticationServiceProtocol [P]
- [ ] Task 10: 定义 UserSessionManagerProtocol [P]
- [ ] Task 11: 定义 ValidationServiceProtocol [P]

#### 4. Service Implementation 任务 (Business Logic)
- [ ] Task 12: 实现 ValidationService + 单元测试
- [ ] Task 13: 实现 AuthenticationService + 单元测试
- [ ] Task 14: 实现 UserSessionManager + 单元测试

#### 5. ViewModels 任务 (Presentation Logic)
- [ ] Task 15: 实现 LoginViewModel + 单元测试
- [ ] Task 16: 实现 SignUpViewModel + 单元测试
- [ ] Task 17: 实现 ForgotPasswordViewModel + 单元测试

#### 6. UI Components 任务 (View Layer)
- [ ] Task 18: 实现 EmailTextField 组件 [P]
- [ ] Task 19: 实现 PasswordTextField 组件 [P]
- [ ] Task 20: 实现 AuthButton 组件 [P]
- [ ] Task 21: 实现 AuthErrorView 组件 [P]

#### 7. Main Views 任务 (Screens)
- [ ] Task 22: 实现 LoginView
- [ ] Task 23: 实现 SignUpView
- [ ] Task 24: 实现 ForgotPasswordView
- [ ] Task 25: 实现 AuthenticationView (coordinator)

#### 8. Integration 任务 (App Integration)
- [ ] Task 26: 更新 IdeaBoxApp.swift 添加认证状态检查
- [ ] Task 27: 更新 ContentView.swift 添加条件渲染

#### 9. Integration Tests 任务 (E2E Testing)
- [ ] Task 28: 编写邮箱注册流程集成测试
- [ ] Task 29: 编写邮箱登录流程集成测试
- [ ] Task 30: 编写密码重置流程集成测试
- [ ] Task 31: 编写会话持久化集成测试

#### 10. Documentation & Polish 任务
- [ ] Task 32: 编写 API 文档注释
- [ ] Task 33: 添加 VoiceOver 标签
- [ ] Task 34: 暗黑模式适配验证
- [ ] Task 35: 性能基准测试

### Ordering Strategy

**TDD Order**: 
1. Contracts (Protocols) → Tests → Implementation
2. Bottom-up: Models → Services → ViewModels → Views

**Dependency Order**:
```
Models (5-8) → Contracts (9-11) → Services (12-14) → ViewModels (15-17) → Components (18-21) → Views (22-25) → Integration (26-27) → E2E Tests (28-31) → Polish (32-35)
```

**Parallel Execution Markers**:
- `[P]` = 可以并行执行的独立任务
- Models 可以并行编写
- UI Components 可以并行编写
- 单元测试可以与实现并行（不同文件）

### Estimated Output

**总任务数**: 约 35 个结构化任务  
**关键路径**: Infrastructure → Models → Services → ViewModels → Views → Integration → Testing  
**并行任务数**: 约 15 个可并行任务  
**估计开发时间**: 2-3 天（单人全职）

**IMPORTANT**: 实际的 `tasks.md` 文件将由 `/tasks` 命令生成，不在 `/plan` 命令范围内。

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
- 生成详细的、可执行的任务清单
- 每个任务包含：目标、输入、输出、验收标准
- 任务按依赖顺序排列

**Phase 4**: Implementation (execute tasks.md)  
- 按 TDD 原则执行任务
- Tests first → Implementation → Refactor
- 持续集成测试验证

**Phase 5**: Validation  
- 运行完整测试套件
- 执行 quickstart.md 验证
- 性能基准测试
- 安全审查

**Phase 6**: Phase 2 准备 (Apple Sign In)  
- Apple Developer 账号付费
- 添加 Sign in with Apple capability
- 扩展 AuthenticationService 支持 Apple
- 更新 UI 支持多登录方式

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

**无违规项** - 本实现方案遵循标准的 iOS 架构模式和最佳实践。

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) ✅
- [x] Phase 1: Design complete (/plan command) ✅
- [x] Phase 2: Task planning complete (/plan command - describe approach only) ✅
- [ ] Phase 3: Tasks generated (/tasks command) ⏸️
- [ ] Phase 4: Implementation complete ⏸️
- [ ] Phase 5: Validation passed ⏸️

**Gate Status**:
- [x] Initial Constitution Check: PASS ✅
- [x] Post-Design Constitution Check: PASS ✅
- [x] All NEEDS CLARIFICATION resolved ✅
- [x] Complexity deviations documented: N/A (no deviations) ✅

**Artifacts Generated**:
- [x] plan.md (this file) ✅
- [x] research.md ✅
- [x] data-model.md ✅
- [x] contracts/AuthenticationService.md ✅
- [x] contracts/UserSessionManager.md ✅
- [x] contracts/ValidationService.md ✅
- [x] quickstart.md ✅
- [x] .cursor/rules/specify-rules.mdc (updated) ✅

---

## Next Steps

### Immediate Actions (Human Review)

1. **Review this plan** for completeness and accuracy
2. **Verify Firebase project** is created and configured
3. **Approve architectural decisions** (MVVM, module structure)
4. **Execute artifact generation**:
   - Generate research.md
   - Generate data-model.md
   - Generate contract files
   - Generate quickstart.md

### After Approval

1. **Run `/tasks` command** to generate detailed task breakdown
2. **Begin implementation** following TDD principles
3. **Track progress** using tasks.md checklist
4. **Continuous testing** with each task completion

---

**Status**: ✅ **Planning Complete - Ready for /tasks command**

*Last Updated*: 2025-10-20  
*Next Command*: `/tasks` to generate implementation tasks  
*Phase 2 Preparation*: Will begin after Phase 1 validation and Apple Developer account setup

---
*Based on Feature Spec: [010-apple-sign-in/spec.md](./spec.md)*  
*Constitution: Generic iOS Best Practices (project constitution pending)*
