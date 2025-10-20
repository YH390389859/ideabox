# Feature Specification: Apple Sign In 和 Firebase 邮箱登录

**Feature Branch**: `010-apple-sign-in`  
**Created**: 2025-10-20  
**Status**: Ready for Planning ✅  
**Input**: User description: "实现 Apple Sign In 和 Firebase 邮箱登录功能"

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story

**作为** 一个 IdeaBox 应用的新用户  
**我想要** 使用我的 Apple ID 或邮箱快速登录  
**以便** 我可以开始使用日历功能，并在多设备间同步我的数据

**作为** 一个注重隐私的用户  
**我想要** 使用 Apple Sign In 的隐私保护功能  
**以便** 我可以控制分享给应用的个人信息

**作为** 一个没有 Apple ID 或偏好传统登录方式的用户  
**我想要** 使用邮箱和密码登录  
**以便** 我可以在任何平台访问我的账号

### Acceptance Scenarios

#### Scenario 1: 首次使用 Apple Sign In 登录
1. **Given** 用户是首次打开应用，尚未登录
2. **When** 用户点击"使用 Apple 登录"按钮
3. **Then** 系统显示 Apple 的认证界面
4. **And** 用户完成 Face ID/Touch ID 验证
5. **Then** 系统创建用户账号并自动登录
6. **And** 用户进入应用主界面（日历视图）
7. **And** 用户的登录状态被持久化保存

#### Scenario 2: 使用邮箱密码注册新账号
1. **Given** 用户选择使用邮箱登录
2. **When** 用户输入邮箱地址和密码（首次注册）
3. **Then** 系统验证邮箱格式和密码强度
4. **And** 系统发送验证邮件到用户邮箱
5. **When** 用户点击验证邮件中的链接
6. **Then** 账号被激活，用户可以登录
7. **And** 用户进入应用主界面

#### Scenario 3: 使用邮箱密码登录已有账号
1. **Given** 用户已有账号并选择邮箱登录
2. **When** 用户输入正确的邮箱和密码
3. **Then** 系统验证凭据
4. **And** 用户成功登录进入主界面
5. **And** 用户的日历数据从云端同步到本地

#### Scenario 4: 多设备登录同一账号
1. **Given** 用户在设备 A 上已登录
2. **When** 用户在设备 B 上使用相同账号登录
3. **Then** 两台设备都保持登录状态
4. **And** 用户数据在两台设备间实时同步

#### Scenario 5: 退出登录
1. **Given** 用户已登录应用
2. **When** 用户在设置中点击"退出登录"
3. **Then** 系统清除本地登录状态
4. **And** 用户返回到登录界面
5. **And** 本地敏感数据被清除

#### Scenario 6: 忘记密码重置
1. **Given** 用户忘记了邮箱登录的密码
2. **When** 用户点击"忘记密码"
3. **Then** 系统发送重置密码的邮件
4. **When** 用户点击邮件中的重置链接
5. **Then** 用户可以设置新密码
6. **And** 用户可以使用新密码登录

### Edge Cases

#### 网络相关
- 用户在没有网络连接时尝试登录？
  - **Expected**: 显示友好的错误提示："请检查网络连接后重试"
  
- 登录过程中网络突然中断？
  - **Expected**: 显示错误提示，允许用户重试

#### 输入验证
- 用户输入无效的邮箱格式？
  - **Expected**: 实时显示格式错误提示
  
- 用户输入的密码不符合强度要求？
  - **Expected**: 显示密码要求提示（最少 8 位，包含字母和数字）

#### Apple Sign In 特殊情况
- 用户取消 Apple Sign In 认证流程？
  - **Expected**: 返回登录界面，不显示错误
  
- 用户的 Apple ID 被禁用或无效？
  - **Expected**: 显示具体错误信息，建议使用邮箱登录

#### 账号状态
- 邮箱已被其他账号注册？
  - **Expected**: 提示用户该邮箱已注册，引导至登录流程
  
- 用户尝试登录但账号未验证邮箱？
  - **Expected**: 提示需要验证邮箱，提供重新发送验证邮件选项

#### 会话管理
- 用户 30 天未使用应用，登录状态过期？
  - **Expected**: 提示会话已过期，要求重新登录
  
- 用户在其他设备修改了密码？
  - **Expected**: 当前设备登录状态失效，要求重新登录

---

## Requirements *(mandatory)*

### Functional Requirements

> **实施说明**：
> - ✅ **[Phase 1]** = 立即实施的需求
> - ⏸️ **[Phase 2]** = Apple 账号付费后实施的需求
> - 📋 **[Both]** = 两个阶段都需要的需求

---

#### 登录方式
- **FR-001** ⏸️ **[Phase 2]**: 系统必须支持 Apple Sign In 作为主要登录方式
- **FR-002** ✅ **[Phase 1]**: 系统必须支持邮箱/密码登录作为备选登录方式
- **FR-003** ⏸️ **[Phase 2]**: 系统必须在登录界面清晰展示两种登录方式的入口
- **FR-004** 📋 **[Both]**: 首次使用任一登录方式都应自动创建用户账号

#### Apple Sign In ⏸️ **[全部 Phase 2]**
- **FR-005** ⏸️: 使用 Apple Sign In 时，系统必须支持 Face ID/Touch ID 快速认证
- **FR-006** ⏸️: 系统必须遵守 Apple 的隐私要求，正确处理用户选择"隐藏我的邮箱"的情况
- **FR-007** ⏸️: Apple Sign In 认证成功后，用户必须能够立即访问应用功能
- **FR-008** ⏸️: 用户可以选择撤销 Apple Sign In 授权，系统必须正确处理此情况

#### 邮箱/密码登录 ✅ **[全部 Phase 1]**
- **FR-009** ✅: 系统必须验证邮箱地址的格式有效性（实时验证）
- **FR-010** ✅: 系统必须要求密码符合安全标准：最少 8 位字符，包含字母和数字
- **FR-011** ✅: 首次使用邮箱注册时，系统必须发送验证邮件
- **FR-012** ✅: 用户必须验证邮箱后才能使用完整功能
- **FR-013** ✅: 系统必须提供"忘记密码"功能，通过邮件重置密码
- **FR-014** ✅: 密码输入框必须支持显示/隐藏密码功能

#### 账号管理
- **FR-015** ✅ **[Phase 1]**: 同一邮箱地址不能注册多个账号
- **FR-016** ⏸️ **[Phase 2]**: Apple ID 和邮箱账号是独立的账号体系，不支持账号关联或合并
- **FR-017** 📋 **[Both]**: 用户必须能够在设置中查看当前登录方式（Phase 1 只显示邮箱）
- **FR-018** ✅ **[Phase 1]**: 用户必须能够退出登录
- **FR-019** ✅ **[Phase 1]**: 退出登录时，系统必须清除本地敏感数据

#### 会话管理 ✅ **[全部 Phase 1]**
- **FR-020** ✅: 用户登录后，登录状态必须持久化保存
- **FR-021** ✅: 应用重启后，已登录用户应保持登录状态
- **FR-022** ✅: 多设备可以同时登录同一账号
- **FR-023** ✅: 登录会话有效期为 30 天，过期后需要重新登录
- **FR-024** ✅: 用户可以选择"记住我"选项以延长会话有效期至 90 天

#### 用户体验 ✅ **[全部 Phase 1]**
- **FR-025** ✅: 登录界面必须设计简洁，符合应用的整体 UI 风格
- **FR-026** ✅: 所有登录相关的操作必须提供即时的加载状态反馈
- **FR-027** ✅: 所有错误信息必须清晰友好，避免技术术语
- **FR-028** ✅: 首次登录成功后，直接进入主界面，不显示新手引导

#### 数据同步 ✅ **[全部 Phase 1]**
- **FR-029** ✅: 登录成功后，用户的日历数据必须自动从云端同步
- **FR-030** ✅: 退出登录时，本地数据必须保留云端备份
- **FR-031** ✅: 重新登录时，本地数据必须与云端数据合并（避免数据丢失）

#### 安全性 ✅ **[全部 Phase 1]**
- **FR-032** ✅: 密码必须加密存储，不得以明文形式保存
- **FR-033** ✅: 所有登录相关的网络通信必须使用加密连接
- **FR-034** ✅: 连续登录失败 5 次后，账号临时锁定 15 分钟
- **FR-035** ✅: 系统必须检测并阻止常见的弱密码（如"12345678"、"password"等）

#### 错误处理 ✅ **[全部 Phase 1]**
- **FR-036** ✅: 网络错误时，必须提供重试选项
- **FR-037** ✅: 认证失败时，必须明确告知失败原因（邮箱未注册、密码错误等）
- **FR-038** ✅: 系统错误时，必须提供用户可理解的错误说明和建议操作

### Non-Functional Requirements

#### 性能
- **NFR-001**: 登录流程从点击按钮到完成不应超过 3 秒（网络正常情况下）
- **NFR-002**: 登录界面必须在 1 秒内加载完成
- **NFR-003**: Face ID/Touch ID 验证必须即时响应

#### 可用性
- **NFR-004**: 登录界面必须支持深色/浅色模式
- **NFR-005**: 所有输入框必须支持自动填充（AutoFill）
- **NFR-006**: 键盘输入必须流畅，无卡顿
- **NFR-007**: 必须支持 VoiceOver 等辅助功能

#### 兼容性
- **NFR-008**: 必须支持 iOS 15.0 及以上版本
- **NFR-009**: 必须支持所有 iPhone 和 iPad 设备
- **NFR-010**: 必须适配不同屏幕尺寸

### Key Entities

#### User (用户)
- **描述**: 使用应用的个人用户
- **关键属性**:
  - 唯一标识符（用户 ID）
  - 登录方式类型（Apple Sign In 或邮箱）
  - Apple ID（如适用）
  - 邮箱地址
  - 显示名称
  - 头像（可选）
  - 创建时间
  - 最后登录时间
  - 邮箱验证状态
- **关系**:
  - 一个用户可以拥有多个日历事件
  - 一个用户只有一个账号设置

#### Authentication Session (认证会话)
- **描述**: 用户的登录状态信息
- **关键属性**:
  - 会话令牌
  - 创建时间
  - 过期时间
  - 设备信息
  - 登录方式
- **关系**:
  - 每个会话关联一个用户
  - 一个用户可以有多个活跃会话（多设备）

#### User Profile (用户配置)
- **描述**: 用户的个人设置和偏好
- **关键属性**:
  - 显示语言
  - 时区设置
  - 通知偏好
  - 主题偏好（深色/浅色）
- **关系**:
  - 每个用户有一个配置文件

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

### Clarification Decisions (Confirmed)
1. **会话过期策略**: 30 天会话有效期，支持"记住我"选项延长至 90 天 ✅
2. **账号关联功能**: 不支持账号关联，Apple ID 和邮箱是独立账号体系 ✅
3. **新手引导**: 不需要新手引导，首次登录直接进入主界面 ✅
4. **登录失败保护**: 5 次失败后锁定 15 分钟 ✅

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted (两种登录方式、用户认证、数据同步)
- [x] Ambiguities marked and resolved (4 items confirmed)
- [x] User scenarios defined (6 acceptance scenarios + edge cases)
- [x] Requirements generated (38 functional requirements + 10 non-functional requirements)
- [x] Entities identified (User, Authentication Session, User Profile)
- [x] Review checklist passed

**Status**: ✅ **Specification complete and ready for planning phase**

---

## Implementation Phases (实施阶段)

### 📋 **分阶段实施策略说明**

由于 Apple Developer 账号尚未付费（$99/年），本功能将分两个阶段实施：

---

### **Phase 1: Firebase 邮箱登录系统** ✅ **立即实施**

#### 📦 实施范围

**核心功能**：
- ✅ 邮箱/密码用户注册
- ✅ 邮箱/密码用户登录
- ✅ 邮箱验证流程
- ✅ 忘记密码/重置密码
- ✅ 用户会话管理
- ✅ 登录状态持久化
- ✅ 多设备登录支持
- ✅ 用户数据云端存储
- ✅ 退出登录功能

**UI 组件**：
- ✅ 登录/注册界面
- ✅ 邮箱输入框（带实时验证）
- ✅ 密码输入框（带显示/隐藏）
- ✅ 忘记密码入口
- ✅ 加载状态指示器
- ✅ 错误提示组件

#### 🎯 Phase 1 目标

```
功能完整度: 80%
用户体验: 完整可用
开发时间: 2-3 天
测试环境: 模拟器 + 真机（7天免费签名）
```

#### 📋 依赖项（Phase 1）

**✅ 已满足的依赖**：
- Firebase 项目（免费创建）
- Firebase iOS SDK（开源，免费）
- GoogleService-Info.plist 配置文件
- Xcode 15.0+
- iOS 15.0+ 目标版本

**❌ 不需要的依赖**：
- ❌ 付费 Apple Developer 账号
- ❌ 应用签名和配置文件
- ❌ App Store Connect 访问权限

#### 💰 成本（Phase 1）

```
开发成本: $0
Firebase: 免费（Spark 计划）
Apple Developer: 暂不需要
总成本: $0 ✨
```

#### 🚀 可立即开始

Phase 1 可以在今天开始开发，无需等待任何审核或付费流程。

---

### **Phase 2: Apple Sign In 集成** ⏸️ **待 Apple 账号付费后**

#### 📦 实施范围

**新增功能**：
- ⏸️ Apple Sign In 按钮
- ⏸️ Face ID/Touch ID 集成
- ⏸️ Apple 隐私功能（隐藏邮箱等）
- ⏸️ 多登录方式共存
- ⏸️ Apple Sign In 优先展示

**UI 更新**：
- ⏸️ 在登录界面添加 Apple Sign In 按钮
- ⏸️ 调整布局以适应两种登录方式
- ⏸️ 添加登录方式选择引导

#### 🎯 Phase 2 目标

```
功能完整度: 100%
Apple Sign In 使用率: 目标 60%
增量开发时间: 0.5 天
用户体验: 极致流畅
```

#### 📋 依赖项（Phase 2）

**⏸️ 等待满足的依赖**：
- 付费 Apple Developer 账号（$99/年）
- App ID 配置（启用 Sign in with Apple）
- Xcode Capability 配置
- 真机测试环境（需要签名）

#### 💰 成本（Phase 2）

```
Apple Developer 账号: $99/年（¥688/年）
开发成本: 0.5 天
Firebase: 仍然免费
总增量成本: $99/年
```

#### ⏰ 启动时机

```
触发条件:
✓ Apple Developer 账号已付费
✓ Phase 1 已完成并测试通过
✓ 已有真实用户使用邮箱登录
✓ 确认产品方向正确

预计时间: 1-2 周后（根据实际情况）
```

---

### **🔄 两阶段的关系**

#### 架构兼容性

```swift
// 统一的认证接口（Phase 1 实现）
protocol AuthenticationService {
    func signIn(with method: AuthMethod) async throws -> User
    func signOut() throws
    func currentUser() -> User?
}

// Phase 1: 只有邮箱登录
enum AuthMethod {
    case email(email: String, password: String)
    // Phase 2 添加: case apple(credential: AuthCredential)
}
```

**设计原则**：
- ✅ Phase 1 的代码无需重构
- ✅ Phase 2 只是添加新的登录方式
- ✅ 已有用户数据不受影响
- ✅ 两种登录方式独立运作

#### 用户影响

**Phase 1 用户**：
```
1. 使用邮箱注册并登录
2. 正常使用所有日历功能
3. 数据安全存储在 Firebase

Phase 2 上线后：
4. 看到新增的 Apple Sign In 按钮
5. 可以继续使用邮箱登录（无影响）
6. 或者创建新的 Apple ID 账号
```

**新用户（Phase 2 后）**：
```
1. 看到两种登录方式
2. 优先推荐 Apple Sign In（更快速）
3. 也可以选择邮箱登录
```

---

### **📊 功能对比表**

| 功能特性 | Phase 1 | Phase 2 |
|---------|---------|---------|
| **邮箱/密码登录** | ✅ | ✅ |
| **Apple Sign In** | ❌ | ✅ |
| **邮箱验证** | ✅ | ✅ |
| **忘记密码** | ✅ | ✅ |
| **Face ID/Touch ID** | ❌ | ✅ |
| **会话管理** | ✅ | ✅ |
| **多设备同步** | ✅ | ✅ |
| **数据安全** | ✅ | ✅ |
| **成本** | $0 | $99/年 |
| **开发时间** | 2-3天 | +0.5天 |

---

### **🎯 Phase 1 成功指标**

完成 Phase 1 后，以下指标将验证系统是否准备好进入 Phase 2：

#### 技术指标
- ✅ 登录成功率 > 95%
- ✅ 平均登录时间 < 3 秒
- ✅ 错误率 < 5%
- ✅ 无重大安全漏洞

#### 业务指标
- ✅ 至少 10 个真实用户完成注册
- ✅ 7日留存率 > 30%
- ✅ 用户反馈积极
- ✅ 核心日历功能稳定运行

#### 架构指标
- ✅ 代码结构清晰，易于扩展
- ✅ 测试覆盖率 > 60%
- ✅ 性能表现良好
- ✅ 文档完整

**当这些指标达成时**，即可确认投入 $99 进入 Phase 2 是值得的。

---

### **⚠️ 风险和缓解措施**

#### Phase 1 潜在风险

| 风险 | 影响 | 缓解措施 |
|-----|------|---------|
| 用户觉得只有邮箱登录不够好 | 中 | UI 设计简洁专业，体验流畅 |
| Firebase 免费额度不足 | 低 | 免费额度支持 10,000+ 用户 |
| 邮箱验证邮件进入垃圾箱 | 中 | 提供重新发送功能，提示检查垃圾箱 |
| 真机测试签名过期（7天） | 低 | 定期重新签名，或主要用模拟器 |

#### Phase 2 延迟风险

| 风险 | 影响 | 缓解措施 |
|-----|------|---------|
| 长期不实施 Apple Sign In | 低 | 邮箱登录已经完整可用 |
| 错过 Apple 的强制要求 | 中 | 提交 App Store 前必须实施 |
| 用户习惯邮箱登录不愿切换 | 低 | 两种方式共存，用户自由选择 |

---

## Next Steps (按阶段)

### 📅 **立即行动（Phase 1）**

1. ✅ **业务决策**: 已确认分阶段实施策略
2. ✅ **技术规划**: 准备就绪，执行 `/plan` 创建 Phase 1 实施计划
3. **Firebase 配置**: 创建项目并下载配置文件（10 分钟）
4. **UI 设计**: 设计邮箱登录界面（符合 Figma 风格）
5. **开发实施**: 开始编码（2-3 天）
6. **测试验证**: 模拟器 + 真机测试

### 📅 **后续行动（Phase 2）**

1. **Apple 账号付费**: 在合适时机支付 $99/年
2. **App ID 配置**: 启用 Sign in with Apple capability
3. **增量开发**: 添加 Apple Sign In 功能（0.5 天）
4. **真机测试**: 测试 Face ID/Touch ID 集成
5. **App Store 准备**: 准备上架材料
6. **安全审查**: 最终安全评审

---

## Appendix: User Flow Diagrams

### Phase 1 用户流程（当前实施）

```
[应用启动]
    ↓
[检查登录状态]
    ↓
    ├─→ [已登录] → [进入主界面] → [同步数据]
    │
    └─→ [未登录] → [登录界面]
                      ↓
                  [邮箱登录]
                      ↓
            ┌─────────┴─────────┐
            ↓                   ↓
        [新用户]             [已有账号]
            ↓                   ↓
      [注册流程]            [登录流程]
            ↓                   ↓
    [输入邮箱+密码]        [输入邮箱+密码]
            ↓                   ↓
    [邮箱格式验证]          [验证凭据]
            ↓                   ↓
    [密码强度验证]          [认证成功]
            ↓                   │
    [创建账号]                 │
            ↓                   │
    [发送验证邮件]              │
            ↓                   │
    [等待邮箱验证] ─────────────┘
            ↓
    [创建/更新用户数据]
            ↓
      [进入主界面]
            ↓
      [同步数据]
```

### Phase 2 用户流程（未来扩展）

```
[应用启动]
    ↓
[检查登录状态]
    ↓
    ├─→ [已登录] → [进入主界面] → [同步数据]
    │
    └─→ [未登录] → [登录界面]
                      ↓
                ┌─────┴─────┐
                ↓           ↓
         [Apple Sign In]  [邮箱登录]
         （推荐⭐）       （备选）
                ↓           ↓
          [Face ID验证]  [输入凭据]
                ↓           ↓
                └─────┬─────┘
                      ↓
                [认证成功]
                      ↓
            [创建/更新用户数据]
                      ↓
                [进入主界面]
                      ↓
                [同步数据]
```

---

## Success Metrics (按阶段)

### Phase 1 成功指标

#### 核心指标
1. **注册完成率**: 90% 的开始注册的用户在 24 小时内完成邮箱验证
2. **登录成功率**: 95% 的登录尝试成功（排除用户输入错误）
3. **登录速度**: 平均登录时间 < 3 秒（网络正常情况下）
4. **错误率**: 系统错误 < 5%（排除用户输入错误）
5. **用户留存**: 完成登录的用户 7 日留存率 > 30%

#### 体验指标
6. **邮箱验证邮件送达率**: > 95%
7. **密码重置成功率**: > 90%
8. **界面响应速度**: 所有操作响应时间 < 500ms
9. **会话稳定性**: 30 天内无异常登出 > 99%

#### 技术指标
10. **API 成功率**: Firebase API 调用成功率 > 99%
11. **崩溃率**: 登录相关崩溃 < 0.1%
12. **内存使用**: 登录流程内存增量 < 50MB

### Phase 2 增量指标（未来）

当 Apple Sign In 上线后，额外追踪：

1. **Apple Sign In 采用率**: 目标 60% 的新用户选择 Apple Sign In
2. **Face ID 成功率**: > 95%
3. **Apple 登录速度**: 平均 < 1 秒
4. **用户偏好分布**: Apple Sign In vs 邮箱登录的比例

### 业务目标（Phase 1 验证后）

达成以下目标后，确认进入 Phase 2：

- ✅ 累计注册用户 ≥ 10 人
- ✅ 日活跃用户 ≥ 3 人
- ✅ 核心日历功能稳定运行 7 天无重大问题
- ✅ 用户反馈整体积极（满意度 > 70%）
- ✅ 无严重安全漏洞或数据泄露

---

## Requirements Summary (需求统计)

### Phase 1 需求分解

| 类别 | 需求数量 | 状态 |
|-----|---------|------|
| 邮箱/密码登录 | 6 个 (FR-009 ~ FR-014) | ✅ 立即实施 |
| 账号管理 | 3 个 (FR-015, FR-018, FR-019) | ✅ 立即实施 |
| 会话管理 | 5 个 (FR-020 ~ FR-024) | ✅ 立即实施 |
| 用户体验 | 4 个 (FR-025 ~ FR-028) | ✅ 立即实施 |
| 数据同步 | 3 个 (FR-029 ~ FR-031) | ✅ 立即实施 |
| 安全性 | 4 个 (FR-032 ~ FR-035) | ✅ 立即实施 |
| 错误处理 | 3 个 (FR-036 ~ FR-038) | ✅ 立即实施 |
| **Phase 1 总计** | **28 个功能需求** | ✅ |

### Phase 2 需求分解

| 类别 | 需求数量 | 状态 |
|-----|---------|------|
| Apple Sign In | 4 个 (FR-005 ~ FR-008) | ⏸️ 待实施 |
| 多登录方式支持 | 2 个 (FR-001, FR-003) | ⏸️ 待实施 |
| 账号管理扩展 | 1 个 (FR-016) | ⏸️ 待实施 |
| **Phase 2 总计** | **7 个功能需求** | ⏸️ |

### 整体需求概览

```
总功能需求: 38 个
├─ Phase 1 (立即实施): 28 个 (74%)
├─ Phase 2 (待实施): 7 个 (18%)
└─ 两阶段共享: 3 个 (8%)

非功能需求: 10 个
└─ 全部在 Phase 1 实施
```

### 开发工作量估算

| 阶段 | 功能需求 | 开发时间 | 测试时间 | 总计 |
|-----|---------|---------|---------|------|
| **Phase 1** | 28 个 | 16-20 小时 | 4-6 小时 | **2-3 天** |
| **Phase 2** | 7 个 | 3-4 小时 | 1-2 小时 | **0.5 天** |

---
