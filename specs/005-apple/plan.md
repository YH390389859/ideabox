# Implementation Plan: Apple 风格底部导航栏重设计

**Branch**: `005-apple` | **Date**: 2025-10-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-apple/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → ✓ Loaded: /Users/echonull/Desktop/project/ideabox/specs/005-apple/spec.md
2. Fill Technical Context
   → ✓ Detected: iOS SwiftUI mobile application
   → ✓ Project Type: Mobile (single app structure)
3. Fill Constitution Check section
   → ⚠️ Constitution file is template only, using general best practices
4. Evaluate Constitution Check section
   → ✓ No violations detected
   → ✓ Updated Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → ✓ All requirements clear, no NEEDS CLARIFICATION
6. Execute Phase 1 → contracts, data-model.md, quickstart.md
   → ✓ Ready to generate design artifacts
7. Re-evaluate Constitution Check section
   → ✓ Design follows Apple HIG principles
   → ✓ Updated Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach
   → ✓ Strategy defined below
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 9. Phase 2 is executed by the /tasks command.

## Summary

**主要需求**: 按照 Apple Human Interface Guidelines 重新设计底部导航栏，提供符合 iOS 原生体验的视觉和交互设计，包括毛玻璃效果、触觉反馈、深色模式支持和流畅动画。

**技术方法**: 
- 使用 SwiftUI 原生组件和修饰符实现 Apple 标准的视觉效果
- 采用 SF Symbols 图标系统
- 集成 UIFeedbackGenerator 提供触觉反馈
- 使用 @Environment 监听系统外观和辅助功能设置
- 通过 matchedGeometryEffect 实现流畅的状态转换动画

## Technical Context

**Language/Version**: Swift 5.9+ (iOS 15.0+)
**Primary Dependencies**: 
- SwiftUI (原生 UI 框架)
- SF Symbols 3.0+ (系统图标库)
- UIKit (触觉反馈 - UIFeedbackGenerator)

**Storage**: N/A (UI 层组件，状态管理通过 @Binding)
**Testing**: XCTest (已有测试框架 - IdeaBoxTests/)
**Target Platform**: iOS 15.0+, iPhone (竖屏)
**Project Type**: Mobile (单一应用结构)

**Performance Goals**: 
- 60fps UI 渲染性能
- <100ms 触摸响应时间
- <50ms 动画帧时间
- 零布局抖动

**Constraints**: 
- 仅支持竖屏模式
- 必须支持深色模式
- 必须支持辅助功能（VoiceOver、动态字体、减少动画）
- 必须符合 Apple HIG 触摸目标尺寸 (44x44 点)
- 必须通过 WCAG 2.1 AA 颜色对比度标准

**Scale/Scope**: 
- 3 个主要导航项（今天、添加、个人中心）
- 支持 2 种外观模式（浅色/深色）
- 集成至现有 ContentView
- 替换现有 BottomNavigationBar.swift

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### SwiftUI 最佳实践
- [x] **组件职责单一**: 导航栏仅负责导航，不包含业务逻辑
- [x] **状态管理清晰**: 使用 @Binding 传递状态，避免 @State 滥用
- [x] **可重用性**: 导航栏组件可独立测试和复用
- [x] **无副作用视图**: 视图计算纯净，副作用在回调中处理

### iOS 开发规范
- [x] **Apple HIG 合规**: 严格遵循人机界面指南
- [x] **系统适配**: 支持深色模式、动态字体、辅助功能
- [x] **性能优化**: 避免过度渲染，使用 Instruments 验证
- [x] **测试覆盖**: UI 测试 + 单元测试 + 预览测试

### 代码质量
- [x] **命名规范**: 遵循 Swift API Design Guidelines
- [x] **注释完整**: 公开接口提供文档注释
- [x] **错误处理**: 优雅降级，不使用 force unwrap
- [x] **可访问性**: 所有交互元素提供 accessibility 标签

## Project Structure

### Documentation (this feature)
```
specs/005-apple/
├── plan.md              # ✓ This file
├── research.md          # → Phase 0 output
├── data-model.md        # → Phase 1 output
├── quickstart.md        # → Phase 1 output
├── contracts/           # → Phase 1 output
│   ├── NavigationBarStyle.md
│   ├── HapticFeedback.md
│   └── AppearanceAdaptation.md
└── tasks.md             # → Phase 2 output (/tasks command)
```

### Source Code (repository root)
```
IdeaBox/
├── Views/
│   ├── BottomNavigationBar.swift          # 重构：Apple 风格导航栏
│   └── Navigation/                         # 新增：导航相关组件
│       ├── NavigationBarStyle.swift        # 样式定义
│       ├── NavigationButton.swift          # 导航按钮组件
│       └── NavigationHaptics.swift         # 触觉反馈封装
├── Models/
│   └── NavigationState.swift               # 新增：导航状态模型
├── Helpers/
│   └── AppearanceHelper.swift              # 新增：外观适配辅助
└── Extensions/
    ├── View+Haptics.swift                  # 新增：触觉反馈扩展
    └── Color+AppColors.swift               # 新增：颜色系统

IdeaBoxTests/
├── UI/
│   ├── BottomNavigationBarTests.swift      # UI 测试
│   ├── NavigationHapticsTests.swift        # 触觉反馈测试
│   └── AppearanceAdaptationTests.swift     # 外观适配测试
└── Helpers/
    └── AppearanceHelperTests.swift         # 辅助类测试
```

**Structure Decision**: 采用 iOS 单一应用结构，按功能分层组织（Views/Models/Helpers/Extensions）。新增 Navigation 子目录用于组织导航相关的可重用组件，保持代码模块化和可测试性。

## Phase 0: Outline & Research

### Research Topics

#### 1. SwiftUI 毛玻璃效果实现
**研究目标**: 如何实现 Apple 标准的毛玻璃背景效果
**关键问题**:
- 使用 `.background(.ultraThinMaterial)` 还是自定义模糊效果？
- 如何处理深色模式下的毛玻璃效果？
- 性能影响和优化方案？

**研究结论**: 
- **决策**: 使用 SwiftUI 原生的 Material 类型
- **理由**: 
  - 自动适配深色/浅色模式
  - 系统级性能优化
  - 符合 Apple 设计标准
- **实现**: `.background(.ultraThinMaterial)` 或 `.ultraThinMaterial` modifier

#### 2. 触觉反馈集成方案
**研究目标**: 确定在 SwiftUI 中实现触觉反馈的最佳方式
**关键问题**:
- 使用 UIImpactFeedbackGenerator 还是其他 Generator？
- 如何封装为 SwiftUI 友好的 API？
- 如何避免创建过多 Generator 实例影响性能？

**研究结论**:
- **决策**: 创建 View+Haptics 扩展封装 UIImpactFeedbackGenerator
- **理由**:
  - UIImpactFeedbackGenerator 适合按钮点击反馈
  - 扩展方式保持 SwiftUI 声明式风格
  - 单例模式复用 Generator 实例
- **实现**: `.onTapGesture { performHapticFeedback(.light) }`

#### 3. SF Symbols 使用规范
**研究目标**: 确定导航图标的 SF Symbols 选择和样式
**关键问题**:
- "今天"按钮应使用哪个图标？（clock, calendar.badge.clock）
- "添加"按钮使用哪个图标？（plus, plus.circle, plus.app）
- "个人中心"使用哪个图标？（person, person.circle, person.crop.circle）
- 如何处理图标的动态调整？

**研究结论**:
- **决策**: 
  - 今天: `calendar.badge.clock` (带时钟的日历)
  - 添加: `plus.circle.fill` (填充的加号圆圈)
  - 个人: `person.crop.circle.fill` (填充的人像圆圈)
- **理由**:
  - 语义明确，符合 Apple 惯例
  - fill 版本在导航栏中视觉重量更好
  - 支持 SF Symbols 的自动缩放和渲染模式
- **实现**: `Image(systemName: "plus.circle.fill")`

#### 4. 深色模式适配策略
**研究目标**: 确定颜色系统和深色模式适配方案
**关键问题**:
- 使用语义颜色（.primary, .secondary）还是自定义颜色？
- 如何监听系统外观变化？
- 毛玻璃效果在深色模式下的表现？

**研究结论**:
- **决策**: 混合使用语义颜色和自定义 Assets 颜色
- **理由**:
  - 语义颜色自动适配，减少维护成本
  - 品牌色（如系统蓝 #007AFF）使用 Assets 定义浅色/深色变体
  - @Environment(\.colorScheme) 用于特殊适配场景
- **实现**: Assets.xcassets 中定义 Adaptive Colors

#### 5. 动画性能优化
**研究目标**: 确保 60fps 流畅动画
**关键问题**:
- 使用 .animation() 还是 withAnimation()？
- 如何避免动画冲突和卡顿？
- matchedGeometryEffect 的性能影响？

**研究结论**:
- **决策**: 使用 .animation(_:value:) 绑定到特定状态变化
- **理由**:
  - 避免隐式动画导致的意外动画
  - 更精确的动画控制
  - 更好的性能（只动画需要的内容）
- **实现**: `.animation(.easeInOut(duration: 0.25), value: selectedTab)`

#### 6. 辅助功能支持
**研究目标**: 确保完整的辅助功能支持
**关键问题**:
- VoiceOver 标签如何设置？
- 动态字体如何测试？
- 减少动画模式如何检测？

**研究结论**:
- **决策**: 
  - VoiceOver: `.accessibilityLabel()` + `.accessibilityHint()`
  - 动态字体: 使用 `.font(.system(.body))` 等语义字体
  - 减少动画: `@Environment(\.accessibilityReduceMotion)`
- **实现**: 
  ```swift
  @Environment(\.accessibilityReduceMotion) var reduceMotion
  let animationDuration = reduceMotion ? 0 : 0.25
  ```

**Output**: research.md 文件包含以上所有研究结论和决策依据

## Phase 1: Design & Contracts

### 1. Data Model (`data-model.md`)

#### NavigationItem (导航项)
```swift
struct NavigationItem: Identifiable {
    let id: String
    let title: String
    let icon: String           // SF Symbol name
    let selectedIcon: String   // SF Symbol name (selected state)
    let action: () -> Void
    var isVisible: Bool = true
    var badge: Int? = nil      // Future: 徽章数量（当前版本不使用）
}
```

**字段说明**:
- `id`: 唯一标识符，用于导航状态管理
- `title`: 导航项显示文本（用于 VoiceOver）
- `icon`: 默认状态的 SF Symbol 图标名
- `selectedIcon`: 选中状态的图标名（通常是 .fill 版本）
- `action`: 点击回调闭包
- `isVisible`: 可见性控制（如"今天"按钮的条件显示）
- `badge`: 徽章数量（预留，当前不使用）

**验证规则**:
- `icon` 和 `selectedIcon` 必须是有效的 SF Symbol 名称
- `title` 不能为空（用于辅助功能）

#### NavigationState (导航状态)
```swift
struct NavigationState {
    var selectedItemId: String
    var isAnimating: Bool = false
}
```

**字段说明**:
- `selectedItemId`: 当前选中的导航项 ID
- `isAnimating`: 是否正在执行动画（防止动画冲突）

**状态转换**:
- Idle → Selected: 用户点击导航项
- Selected → Idle: 导航完成
- Selected → Animating → Selected: 动画过渡

### 2. API Contracts (`contracts/`)

#### NavigationBarStyle Contract
**文件**: `contracts/NavigationBarStyle.md`

**职责**: 定义导航栏的视觉样式规范

**接口定义**:
```swift
protocol NavigationBarStyleProtocol {
    // 背景效果
    var backgroundMaterial: Material { get }
    
    // 颜色系统
    var accentColor: Color { get }
    var iconColor: Color { get }
    var selectedIconColor: Color { get }
    
    // 尺寸规范
    var buttonSize: CGFloat { get }      // 44x44 点
    var barHeight: CGFloat { get }       // 84 点
    var horizontalPadding: CGFloat { get } // 16 点
    var verticalPadding: CGFloat { get }   // 25 点
    
    // 动画参数
    var animationDuration: TimeInterval { get }
    var animationCurve: Animation { get }
}

struct AppleNavigationBarStyle: NavigationBarStyleProtocol {
    // Apple HIG 标准实现
}
```

**验证标准**:
- ✓ 背景使用 `.ultraThinMaterial` 毛玻璃效果
- ✓ 按钮尺寸 ≥ 44x44 点（HIG 最小触摸目标）
- ✓ 动画时长 0.2-0.3 秒
- ✓ 使用 ease-in-out 缓动曲线

#### HapticFeedback Contract
**文件**: `contracts/HapticFeedback.md`

**职责**: 定义触觉反馈的触发规范

**接口定义**:
```swift
protocol HapticFeedbackProtocol {
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
    func prepare()
}

enum NavigationHapticEvent {
    case buttonTap        // 导航项点击
    case todayButton      // "今天"按钮点击
    case invalidAction    // 无效操作（可选）
}
```

**触发规则**:
- **buttonTap**: 使用 `.light` 风格，所有导航按钮点击时触发
- **todayButton**: 使用 `.medium` 风格，"今天"按钮点击时触发（更强调）
- **timing**: 触觉反馈应在视觉反馈之前或同时触发（<16ms）

**验证标准**:
- ✓ 触觉反馈延迟 < 50ms
- ✓ Generator 预加载（调用 prepare()）
- ✓ 后台时不触发（检查 app state）

#### AppearanceAdaptation Contract
**文件**: `contracts/AppearanceAdaptation.md`

**职责**: 定义系统外观和辅助功能适配规范

**接口定义**:
```swift
protocol AppearanceAdaptable {
    // 外观模式
    func adaptToColorScheme(_ scheme: ColorScheme)
    
    // 辅助功能
    func adaptToDynamicType(_ category: ContentSizeCategory)
    func adaptToReduceMotion(_ enabled: Bool)
    func provideAccessibilityLabels() -> [String: String]
}
```

**适配规则**:
- **深色模式**: 自动调整颜色和对比度
- **动态字体**: 支持 XS ~ XXXL 尺寸
- **减少动画**: 禁用装饰性动画，保留功能性动画
- **VoiceOver**: 提供完整的标签和提示

**验证标准**:
- ✓ 颜色对比度 ≥ 4.5:1 (WCAG AA)
- ✓ 动态字体不破坏布局
- ✓ 所有交互元素有 accessibility label

### 3. Integration Test Scenarios

**测试场景 1: 导航项点击**
```swift
// Given: 用户在首页
// When: 点击"添加"按钮
// Then: 
//   - 触发触觉反馈
//   - 按钮显示按压动画（缩放）
//   - 调用 action 回调
//   - 动画时长 0.2 秒
```

**测试场景 2: "今天"按钮显示/隐藏**
```swift
// Given: 用户查看非今天的日期
// When: "今天"按钮应可见
// Then: 点击后
//   - 按钮淡出（0.25秒）
//   - 日期切换到今天
//   - 触发 onTodayTapped 回调
```

**测试场景 3: 深色模式切换**
```swift
// Given: 应用在浅色模式
// When: 系统切换到深色模式
// Then:
//   - 导航栏背景自动调整为深色毛玻璃
//   - 图标颜色适配深色主题
//   - 无需重新渲染整个视图
```

**测试场景 4: 辅助功能 - VoiceOver**
```swift
// Given: 开启 VoiceOver
// When: 焦点移动到"添加"按钮
// Then:
//   - 读出: "添加按钮"
//   - 提示: "轻点两下以创建新事项"
```

**测试场景 5: 辅助功能 - 减少动画**
```swift
// Given: 开启"减少动画"
// When: 点击导航项
// Then:
//   - 状态切换瞬间完成（0秒动画）
//   - 或使用简化的淡入淡出（≤0.15秒）
```

### 4. Quickstart Test Plan (`quickstart.md`)

**目标**: 验证导航栏在真实场景下的表现

**前置条件**:
- Xcode 14.0+
- iOS 15.0+ 模拟器或真机
- 已编译的 IdeaBox 应用

**测试步骤**:

1. **视觉验证** (2 分钟)
   - 启动应用
   - 检查导航栏是否使用毛玻璃背景
   - 切换深色模式，验证颜色适配
   - 检查按钮尺寸和间距符合 HIG

2. **交互验证** (3 分钟)
   - 点击"添加"按钮，验证触觉反馈
   - 切换到非今天日期，验证"今天"按钮出现
   - 点击"今天"按钮，验证滚动和按钮隐藏
   - 快速连续点击，验证无重复触发

3. **动画验证** (2 分钟)
   - 观察"今天"按钮淡入淡出是否流畅
   - 检查按钮点击的缩放动画
   - 使用 Xcode View Debugger 检查层级

4. **辅助功能验证** (3 分钟)
   - 开启 VoiceOver，验证所有按钮可读
   - 调整文字大小到 XXXL，验证布局
   - 开启"减少动画"，验证动画简化

5. **性能验证** (5 分钟)
   - 使用 Instruments 录制 Core Animation
   - 验证 FPS 保持在 58-60
   - 检查内存占用稳定
   - 验证触摸响应时间 < 100ms

**成功标准**:
- ✓ 所有视觉元素符合 Apple HIG
- ✓ 动画流畅无卡顿（60fps）
- ✓ 触觉反馈及时准确
- ✓ 辅助功能完整可用
- ✓ 无性能警告或内存泄漏

### 5. Update Agent Context

执行更新代理上下文脚本：

```bash
.specify/scripts/bash/update-agent-context.sh cursor
```

**预期输出**: 更新 `.cursorrules` 文件，添加：
- 当前功能：Apple 风格导航栏
- 技术栈：SwiftUI, SF Symbols, UIFeedbackGenerator
- 关键文件：BottomNavigationBar.swift, NavigationBarStyle.swift
- 最近变更：重构导航栏视觉和交互

**Output**: 
- ✓ data-model.md (导航数据模型)
- ✓ contracts/ (3 个契约文档)
- ✓ quickstart.md (快速测试计划)
- ✓ .cursorrules (更新上下文)

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:

1. **从 Phase 1 设计文档生成任务**
   - 每个 contract → 1 个接口定义任务 + 1 个实现任务
   - 每个 data model → 1 个模型创建任务
   - 每个 integration test scenario → 1 个测试任务
   - quickstart.md → 1 个验证任务

2. **任务分类**
   - **[P]** 并行任务：可独立执行的文件创建
   - **[S]** 串行任务：依赖前序任务的实现
   - **[T]** 测试任务：验证实现的测试

3. **TDD 顺序**
   - Phase 1: 创建测试框架和数据模型 [P]
   - Phase 2: 编写失败的测试用例 [S]
   - Phase 3: 实现功能使测试通过 [S]
   - Phase 4: 重构和优化 [S]
   - Phase 5: 集成测试和验证 [T]

**Ordering Strategy**:

1. **基础设施层** (Tasks 1-5) [P]
   - 创建 NavigationState 模型
   - 创建 NavigationBarStyle 协议和实现
   - 创建 HapticFeedback 协议和实现
   - 创建 AppearanceHelper
   - 创建 View+Haptics 扩展

2. **测试层** (Tasks 6-10) [T]
   - 编写 NavigationState 测试（预期失败）
   - 编写 HapticFeedback 测试（预期失败）
   - 编写 AppearanceAdaptation 测试（预期失败）
   - 编写 UI 交互测试（预期失败）
   - 编写 VoiceOver 测试（预期失败）

3. **组件层** (Tasks 11-15) [S]
   - 重构 BottomNavigationBar 使用新样式系统
   - 实现 NavigationButton 子组件
   - 集成触觉反馈
   - 实现深色模式适配
   - 实现辅助功能支持

4. **集成层** (Tasks 16-20) [S]
   - 更新 ContentView 集成新导航栏
   - 修复测试使其通过
   - 性能优化和 Instruments 验证
   - 辅助功能验证
   - quickstart.md 验证

5. **优化和文档** (Tasks 21-25) [P]
   - 代码审查和重构
   - 添加文档注释
   - 更新 README
   - 创建 Preview 示例
   - 最终验证和清理

**Estimated Output**: 25 个有序任务，清晰标记依赖关系和执行顺序

**IMPORTANT**: 这个阶段由 /tasks 命令执行，不是 /plan 命令的一部分

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following Apple HIG and SwiftUI best practices)  
**Phase 5**: Validation (run XCTests, execute quickstart.md, Instruments performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

无违规项需要记录。设计完全符合 SwiftUI 最佳实践和 Apple HIG 规范。

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) ✅ research.md
- [x] Phase 1: Design complete (/plan command) ✅ data-model.md, contracts/, quickstart.md
- [x] Phase 2: Task planning complete (/plan command - described approach) ✅
- [ ] Phase 3: Tasks generated (/tasks command) → Next step
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved (none existed)
- [x] Complexity deviations documented (none)

**Artifacts Generated**:
- [x] plan.md - 实施计划
- [x] research.md - 技术调研
- [x] data-model.md - 数据模型
- [x] contracts/NavigationBarStyle.md - 样式契约
- [x] contracts/HapticFeedback.md - 触觉反馈契约
- [x] contracts/AppearanceAdaptation.md - 外观适配契约
- [x] quickstart.md - 快速验证指南

---

## Next Steps

**立即执行**: 使用 `/tasks` 命令生成详细的任务列表

**准备工作**: 
- ✓ 所有设计决策已明确
- ✓ 技术方案已验证
- ✓ 测试策略已定义

**期望输出**: `tasks.md` 文件包含 25 个可执行任务，遵循 TDD 原则

---
*Based on Apple Human Interface Guidelines and SwiftUI Best Practices*
