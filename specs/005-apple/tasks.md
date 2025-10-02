# Tasks: Apple 风格底部导航栏重设计

**Feature**: 005-apple  
**Input**: Design documents from `/specs/005-apple/`  
**Prerequisites**: ✅ plan.md, ✅ research.md, ✅ data-model.md, ✅ contracts/  
**Branch**: `005-apple`

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → ✓ Loaded: Tech stack Swift 5.9+, SwiftUI, SF Symbols
   → ✓ Extracted: iOS mobile structure, XCTest framework
2. Load optional design documents:
   → ✓ data-model.md: 3 entities (NavigationItem, NavigationState, NavigationBarConfiguration)
   → ✓ contracts/: 3 files (NavigationBarStyle, HapticFeedback, AppearanceAdaptation)
   → ✓ quickstart.md: 6 test scenarios (视觉、交互、动画、辅助功能、性能)
3. Generate tasks by category:
   → Setup: 项目配置、依赖、颜色资源
   → Tests: 3 contract tests, 6 integration tests
   → Core: 3 models, 4 helpers, 2 view components
   → Integration: ContentView 集成、测试修复
   → Polish: 文档、预览、性能验证
4. Apply task rules:
   → [P] marked for parallel tasks (different files)
   → Tests before implementation (TDD mandatory)
5. Total tasks: 30 numbered sequentially (T001-T030)
6. Dependency graph: Setup → Tests → Core → Integration → Polish
7. Parallel execution: T004-T006, T007-T012, T016-T019, T028-T030
8. Validation:
   → ✓ All 3 contracts have tests
   → ✓ All 3 entities have model tasks
   → ✓ All tests before implementation
9. Return: SUCCESS (30 tasks ready for TDD execution)
```

---

## Format: `[ID] [P?] Description`
- **[P]**: 可并行执行（不同文件，无依赖）
- 包含精确文件路径
- TDD 顺序：测试先行，实现随后

## Path Conventions
- **iOS 项目**: `IdeaBox/` (源代码), `IdeaBoxTests/` (测试)
- **视图**: `IdeaBox/Views/`
- **模型**: `IdeaBox/Models/`
- **助手**: `IdeaBox/Helpers/`
- **扩展**: `IdeaBox/Extensions/`

---

## Phase 3.1: Setup (环境和资源准备)

### T001 ✅ 验证 Xcode 项目配置
**文件**: `IdeaBox.xcodeproj/project.pbxproj`
**描述**: 
- 确认最低部署目标为 iOS 15.0+
- 确认 Swift 版本 5.9+
- 验证 SwiftUI 和 UIKit 框架已链接
- 确认 SF Symbols 可用

**验收标准**:
- [ ] iOS Deployment Target = 15.0
- [ ] Swift Language Version = 5.9
- [ ] 编译无警告

**依赖**: 无

---

### T002 [P] 创建颜色资源（NavigationAccent）
**文件**: `IdeaBox/Assets.xcassets/Colors/NavigationAccent.colorset/Contents.json`
**描述**:
- 在 Assets.xcassets 中创建 Colors 文件夹（如不存在）
- 创建 NavigationAccent.colorset
- 定义浅色模式颜色: #007AFF (R:0, G:122, B:255)
- 定义深色模式颜色: #0A84FF (R:10, G:132, B:255)
- 验证 sRGB 色彩空间

**验收标准**:
- [ ] 浅色模式蓝色正确
- [ ] 深色模式蓝色正确
- [ ] Xcode 预览正确显示

**依赖**: 无

---

### T003 [P] 配置 SwiftLint（可选）
**文件**: `.swiftlint.yml` (项目根目录)
**描述**:
- 如果项目使用 SwiftLint，确保配置适合 SwiftUI
- 规则建议: line_length: 120, trailing_whitespace, force_unwrapping
- 排除: .build, Pods, IdeaBox.xcodeproj

**验收标准**:
- [ ] SwiftLint 运行无错误
- [ ] 规则适合当前代码风格

**依赖**: 无

---

## Phase 3.2: Tests First (TDD) ⚠️ **必须在实现前完成且失败**

### T004 [P] Contract Test: NavigationBarStyle
**文件**: `IdeaBoxTests/UI/NavigationBarStyleTests.swift`
**描述**:
- 创建测试类 `NavigationBarStyleTests: XCTestCase`
- 测试方法:
  1. `testButtonSizeCompliesWithHIG()` - 验证按钮尺寸 ≥ 44pt
  2. `testAnimationDurationInRecommendedRange()` - 验证动画时长 0.2-0.4s
  3. `testBarHeightAccommodatesContent()` - 验证导航栏高度足够
  4. `testBackgroundMaterialExists()` - 验证毛玻璃材质
- **预期**: 所有测试失败（因为还没有实现）

**验收标准**:
- [ ] 测试编译通过
- [ ] 所有测试失败（红色）
- [ ] 错误信息清晰

**依赖**: T001

---

### T005 [P] Contract Test: HapticFeedback
**文件**: `IdeaBoxTests/UI/HapticFeedbackTests.swift`
**描述**:
- 创建测试类 `HapticFeedbackTests: XCTestCase`
- 测试方法:
  1. `testTriggerDoesNotThrow()` - 触发触觉不抛异常
  2. `testPrepareSucceeds()` - 预加载成功
  3. `testDebouncing()` - 去抖动功能
  4. `testManagerSingleton()` - 单例模式
- **预期**: 所有测试失败

**验收标准**:
- [ ] 测试编译通过
- [ ] 所有测试失败（红色）

**依赖**: T001

---

### T006 [P] Contract Test: AppearanceAdaptation
**文件**: `IdeaBoxTests/UI/AppearanceAdaptationTests.swift`
**描述**:
- 创建测试类 `AppearanceAdaptationTests: XCTestCase`
- 测试方法:
  1. `testDarkModeColors()` - 深色模式颜色适配
  2. `testDynamicTypeScaling()` - 动态字体缩放
  3. `testReduceMotionAdaptation()` - 减少动画适配
  4. `testColorContrastCompliance()` - 颜色对比度 ≥ 4.5:1
- 使用快照测试（如可用）
- **预期**: 所有测试失败

**验收标准**:
- [ ] 测试编译通过
- [ ] 所有测试失败（红色）

**依赖**: T001, T002

---

### T007 [P] Integration Test: 视觉验证
**文件**: `IdeaBoxTests/UI/BottomNavigationBarVisualTests.swift`
**描述**:
- 测试毛玻璃背景渲染
- 测试 SF Symbols 图标显示（calendar.badge.clock, plus.circle.fill, person.crop.circle.fill）
- 测试按钮尺寸和布局
- 快照测试浅色/深色模式
- **预期**: 测试失败（组件未实现）

**验收标准**:
- [ ] 测试编译通过
- [ ] 测试失败（红色）

**依赖**: T001

---

### T008 [P] Integration Test: 按钮交互
**文件**: `IdeaBoxTests/UI/BottomNavigationBarInteractionTests.swift`
**描述**:
- 测试"添加"按钮点击触发回调
- 测试"今天"按钮点击触发回调
- 测试防重复点击（去抖动）
- 测试触觉反馈触发
- **预期**: 测试失败

**验收标准**:
- [ ] 测试编译通过
- [ ] 测试失败（红色）

**依赖**: T001

---

### T009 [P] Integration Test: "今天"按钮显示逻辑
**文件**: `IdeaBoxTests/UI/TodayButtonVisibilityTests.swift`
**描述**:
- 测试查看今天时按钮隐藏
- 测试查看其他日期时按钮显示
- 测试按钮显示/隐藏动画
- 测试点击后跳转今天
- **预期**: 测试失败

**验收标准**:
- [ ] 测试编译通过
- [ ] 测试失败（红色）

**依赖**: T001

---

### T010 [P] Integration Test: 动画性能
**文件**: `IdeaBoxTests/UI/NavigationBarAnimationTests.swift`
**描述**:
- 测试"今天"按钮淡入淡出动画
- 测试按钮按压动画（spring effect）
- 测试动画时长符合规范（0.2-0.3s）
- 测试减少动画模式适配
- **预期**: 测试失败

**验收标准**:
- [ ] 测试编译通过
- [ ] 测试失败（红色）

**依赖**: T001

---

### T011 [P] Integration Test: VoiceOver 辅助功能
**文件**: `IdeaBoxTests/UI/NavigationBarAccessibilityTests.swift`
**描述**:
- 测试所有按钮有 accessibilityLabel
- 测试"今天"按钮: "今天按钮"
- 测试"添加"按钮: "添加按钮"
- 测试"个人中心"按钮: "个人中心按钮"
- 测试 accessibilityHint 存在
- **预期**: 测试失败

**验收标准**:
- [ ] 测试编译通过
- [ ] 测试失败（红色）

**依赖**: T001

---

### T012 [P] Integration Test: 动态字体适配
**文件**: `IdeaBoxTests/UI/DynamicTypeTests.swift`
**描述**:
- 测试 XS 字体大小下布局完整
- 测试 XXXL 字体大小下无截断
- 测试按钮触摸目标保持 ≥ 44pt
- 测试 @ScaledMetric 使用
- **预期**: 测试失败

**验收标准**:
- [ ] 测试编译通过
- [ ] 测试失败（红色）

**依赖**: T001

---

## Phase 3.3: Core Implementation (仅在测试失败后实施)

### T013 [P] 创建 NavigationItem 模型
**文件**: `IdeaBox/Models/NavigationItem.swift`
**描述**:
- 定义 `NavigationItem` 结构体
- 实现 `Identifiable` 和 `Equatable` 协议
- 字段: id, title, icon, selectedIcon, action, isVisible, badge
- 实现 `validate()` 方法
- 创建 Mock 数据扩展（#if DEBUG）

**验收标准**:
- [ ] 编译无警告
- [ ] Mock 数据可用于预览
- [ ] T004-T006 部分测试开始通过

**依赖**: T004, T005, T006 (测试必须先失败)

---

### T014 [P] 创建 NavigationState 模型
**文件**: `IdeaBox/Models/NavigationState.swift`
**描述**:
- 定义 `NavigationState` 结构体
- 实现 `Equatable` 协议
- 字段: selectedItemId, isAnimating, previousItemId
- 可选: 创建 `NavigationStateManager: ObservableObject`

**验收标准**:
- [ ] 编译无警告
- [ ] 状态转换逻辑清晰

**依赖**: T004-T006

---

### T015 [P] 创建 NavigationBarStyle 协议和实现
**文件**: `IdeaBox/Views/Navigation/NavigationBarStyle.swift`
**描述**:
- 定义 `NavigationBarStyleProtocol` 协议
- 实现 `AppleNavigationBarStyle` 结构体
- 属性: backgroundMaterial, colors, dimensions, animation parameters
- 创建预设配置: .apple, .compact, .large
- 实现 adaptive(for:) 方法

**验收标准**:
- [ ] 编译无警告
- [ ] T004 测试通过（绿色）
- [ ] 预设配置可用

**依赖**: T004 (测试必须先失败)

---

### T016 [P] 创建 HapticManager
**文件**: `IdeaBox/Helpers/HapticManager.swift`
**描述**:
- 定义 `HapticFeedbackProtocol` 协议
- 实现 `HapticManager` 单例类
- 实现触觉反馈方法: trigger(_:), prepare(), triggerNotification(_:), triggerSelection()
- 实现去抖动逻辑（minimumInterval: 0.1s）
- 定义 `NavigationHapticEvent` 枚举

**验收标准**:
- [ ] 编译无警告
- [ ] T005 测试通过（绿色）
- [ ] 真机测试触觉反馈有效

**依赖**: T005 (测试必须先失败)

---

### T017 [P] 创建 View+Haptics 扩展
**文件**: `IdeaBox/Extensions/View+Haptics.swift`
**描述**:
- 扩展 `View` 添加触觉反馈方法
- 实现 `hapticFeedback(_:enabled:)` 修饰符
- 实现 `navigationHaptic(_:enabled:)` 修饰符
- SwiftUI 友好的 API 设计

**验收标准**:
- [ ] 编译无警告
- [ ] 可在 Button 上链式调用
- [ ] T008 部分测试通过

**依赖**: T016

---

### T018 [P] 创建 AppearanceAdapter
**文件**: `IdeaBox/Helpers/AppearanceAdapter.swift`
**描述**:
- 定义 `AppearanceAdaptable` 协议
- 实现 `AppearanceAdapter` 结构体
- 方法: adaptToColorScheme(_:), adaptToDynamicType(_:), adaptToReduceMotion(_:)
- 实现 scaleFactor(for:) 计算
- 提供 accessibilityLabels

**验收标准**:
- [ ] 编译无警告
- [ ] T006 测试通过（绿色）
- [ ] 适配逻辑正确

**依赖**: T006 (测试必须先失败)

---

### T019 [P] 创建 Color+AppColors 扩展
**文件**: `IdeaBox/Extensions/Color+AppColors.swift`
**描述**:
- 扩展 `Color` 添加应用颜色
- 静态属性: `navigationAccent` (读取 Assets)
- 可选: `adaptive(light:dark:)` 方法
- 封装颜色访问逻辑

**验收标准**:
- [ ] 编译无警告
- [ ] 颜色正确读取 Assets
- [ ] T007 部分测试通过

**依赖**: T002

---

### T020 重构 BottomNavigationBar 视图
**文件**: `IdeaBox/Views/BottomNavigationBar.swift`
**描述**:
- 重构现有 BottomNavigationBar
- 应用 AppleNavigationBarStyle
- 集成 HapticManager
- 集成 AppearanceAdapter
- 使用 @Environment 监听系统设置:
  - colorScheme, sizeCategory, accessibilityReduceMotion, accessibilityReduceTransparency
- 实现毛玻璃背景 (.ultraThinMaterial)
- 使用 SF Symbols 图标
- 实现"今天"按钮条件显示逻辑
- 添加 VoiceOver 标签
- 使用 @ScaledMetric 支持动态字体

**验收标准**:
- [ ] 编译无警告
- [ ] T007-T012 测试通过（绿色）
- [ ] 视觉符合设计稿
- [ ] 动画流畅

**依赖**: T013, T014, T015, T016, T017, T018, T019

---

### T021 创建 NavigationButton 子组件（可选）
**文件**: `IdeaBox/Views/Navigation/NavigationButton.swift`
**描述**:
- 提取可重用的导航按钮组件
- 参数: icon, title, action, hapticStyle
- 内置按压动画和触觉反馈
- 辅助功能支持

**验收标准**:
- [ ] 编译无警告
- [ ] BottomNavigationBar 可使用
- [ ] 减少重复代码

**依赖**: T020

---

## Phase 3.4: Integration (集成和测试修复)

### T022 更新 ContentView 集成新导航栏
**文件**: `IdeaBox/ContentView.swift`
**描述**:
- 确保 ContentView 正确使用重构后的 BottomNavigationBar
- 验证 @Binding 传递正确 (selectedDate, showingAddSheet)
- 验证 onTodayTapped 回调正确
- 测试与现有功能的集成

**验收标准**:
- [ ] 应用正常运行
- [ ] 导航栏功能完整
- [ ] 无回归问题

**依赖**: T020

---

### T023 修复失败的测试
**文件**: `IdeaBoxTests/` (多个文件)
**描述**:
- 运行完整测试套件
- 修复任何失败的测试（包括现有测试）
- 确保新代码不破坏现有功能
- 特别检查 TodayButtonIntegrationTests.swift

**验收标准**:
- [ ] 所有测试通过（绿色）
- [ ] 无测试跳过（skip）
- [ ] 测试覆盖率 ≥ 80%

**依赖**: T022

---

### T024 运行 UI 测试（真机和模拟器）
**文件**: N/A (测试运行)
**描述**:
- 在 iPhone 14 Pro 模拟器运行
- 在真机运行（测试触觉反馈）
- 测试浅色/深色模式切换
- 测试动态字体（XS, M, XXXL）
- 测试 VoiceOver 功能
- 测试减少动画模式

**验收标准**:
- [ ] 所有 UI 测试通过
- [ ] 真机触觉反馈正常
- [ ] 辅助功能完整

**依赖**: T023

---

## Phase 3.5: Polish (优化和文档)

### T025 性能优化 - Instruments 验证
**文件**: N/A (性能分析)
**描述**:
- 使用 Xcode Instruments Core Animation
- 验证 FPS ≥ 58
- 检查 Color Offscreen-Rendered（最小化）
- 检查 Color Misaligned Images（消除）
- 使用 Time Profiler 检查触摸响应 < 100ms
- 优化任何性能瓶颈

**验收标准**:
- [ ] FPS 稳定在 58-60
- [ ] 主线程占用 < 80%
- [ ] 无明显性能问题

**依赖**: T024

---

### T026 内存泄漏检查
**文件**: N/A (内存分析)
**描述**:
- 使用 Xcode Memory Graph Debugger
- 检查循环引用
- 验证 HapticManager 不泄漏
- 多次点击按钮，观察内存稳定

**验收标准**:
- [ ] 无内存泄漏
- [ ] 内存占用稳定（± 5MB）

**依赖**: T024

---

### T027 代码审查和重构
**文件**: 所有新增/修改的文件
**描述**:
- 审查代码风格符合 Swift API Guidelines
- 移除重复代码
- 添加文档注释（/// 格式）
- 检查命名清晰性
- 确保错误处理完整（无 force unwrap）

**验收标准**:
- [ ] 代码可读性高
- [ ] 无明显坏味道
- [ ] 符合项目规范

**依赖**: T023

---

### T028 [P] 添加 SwiftUI Previews
**文件**: `IdeaBox/Views/BottomNavigationBar.swift`
**描述**:
- 添加多个 Preview 变体:
  1. 标准预览（今天按钮隐藏）
  2. 今天按钮显示预览
  3. 深色模式预览
  4. 大字体预览
- 使用 Mock 数据
- 验证预览在 Xcode Canvas 正常显示

**验收标准**:
- [ ] 至少 4 个预览变体
- [ ] Canvas 渲染正确
- [ ] 预览辅助开发

**依赖**: T020

---

### T029 [P] 更新 CHANGELOG.md
**文件**: `CHANGELOG.md`
**描述**:
- 添加 005-apple 功能条目
- 描述: "重新设计底部导航栏，采用 Apple HIG 标准"
- 列出关键改进:
  - 毛玻璃效果背景
  - 触觉反馈集成
  - 深色模式和辅助功能支持
  - SF Symbols 图标系统
  - 流畅的 60fps 动画
- 注明破坏性变更（如有）

**验收标准**:
- [ ] CHANGELOG 更新
- [ ] 描述清晰准确

**依赖**: T023

---

### T030 [P] 执行 quickstart.md 验证
**文件**: `specs/005-apple/quickstart.md`
**描述**:
- 按照 quickstart.md 执行完整验证流程（15 分钟）
- 完成所有 ✅ 标记的测试
- 记录验证结果
- 截图保存（浅色/深色/大字体）
- 填写验收标准

**验收标准**:
- [ ] 所有必需测试通过
- [ ] 截图齐全
- [ ] 验收签名完成

**依赖**: T024

---

## Dependencies (依赖关系图)

```
T001 (配置验证)
  ├─→ T002 [P] (颜色资源)
  ├─→ T003 [P] (SwiftLint)
  ├─→ T004 [P] (NavigationBarStyle Test)
  ├─→ T005 [P] (HapticFeedback Test)
  ├─→ T006 [P] (AppearanceAdaptation Test)
  ├─→ T007 [P] (视觉验证 Test)
  ├─→ T008 [P] (交互 Test)
  ├─→ T009 [P] (今天按钮 Test)
  ├─→ T010 [P] (动画性能 Test)
  ├─→ T011 [P] (VoiceOver Test)
  └─→ T012 [P] (动态字体 Test)

T004-T012 (所有测试失败)
  ├─→ T013 [P] (NavigationItem 模型)
  ├─→ T014 [P] (NavigationState 模型)
  ├─→ T015 [P] (NavigationBarStyle 实现)
  ├─→ T016 [P] (HapticManager 实现)
  ├─→ T018 [P] (AppearanceAdapter 实现)
  └─→ T019 [P] (Color 扩展)

T016 → T017 (View+Haptics 扩展)

T013-T019 (所有核心实现)
  └─→ T020 (BottomNavigationBar 重构)
       └─→ T021 (NavigationButton 子组件)
            └─→ T022 (ContentView 集成)
                 └─→ T023 (修复测试)
                      └─→ T024 (UI 测试)
                           ├─→ T025 (性能优化)
                           ├─→ T026 (内存检查)
                           └─→ T027 (代码审查)
                                ├─→ T028 [P] (Previews)
                                ├─→ T029 [P] (CHANGELOG)
                                └─→ T030 [P] (Quickstart验证)
```

---

## Parallel Execution Examples (并行执行示例)

### 批次 1: Setup (可同时执行)
```bash
# T002 和 T003 可以并行
Task: "创建颜色资源 NavigationAccent 在 IdeaBox/Assets.xcassets/"
Task: "配置 SwiftLint 规则在 .swiftlint.yml"
```

### 批次 2: Contract Tests (可同时执行)
```bash
# T004, T005, T006 可以并行（不同文件）
Task: "Contract test NavigationBarStyle 在 IdeaBoxTests/UI/NavigationBarStyleTests.swift"
Task: "Contract test HapticFeedback 在 IdeaBoxTests/UI/HapticFeedbackTests.swift"
Task: "Contract test AppearanceAdaptation 在 IdeaBoxTests/UI/AppearanceAdaptationTests.swift"
```

### 批次 3: Integration Tests (可同时执行)
```bash
# T007-T012 可以并行（不同文件）
Task: "Integration test 视觉验证 在 IdeaBoxTests/UI/BottomNavigationBarVisualTests.swift"
Task: "Integration test 按钮交互 在 IdeaBoxTests/UI/BottomNavigationBarInteractionTests.swift"
Task: "Integration test 今天按钮逻辑 在 IdeaBoxTests/UI/TodayButtonVisibilityTests.swift"
Task: "Integration test 动画性能 在 IdeaBoxTests/UI/NavigationBarAnimationTests.swift"
Task: "Integration test VoiceOver 在 IdeaBoxTests/UI/NavigationBarAccessibilityTests.swift"
Task: "Integration test 动态字体 在 IdeaBoxTests/UI/DynamicTypeTests.swift"
```

### 批次 4: Core Models (可同时执行)
```bash
# T013, T014, T015, T016, T018, T019 可以并行（不同文件）
Task: "创建 NavigationItem 模型 在 IdeaBox/Models/NavigationItem.swift"
Task: "创建 NavigationState 模型 在 IdeaBox/Models/NavigationState.swift"
Task: "创建 NavigationBarStyle 在 IdeaBox/Views/Navigation/NavigationBarStyle.swift"
Task: "创建 HapticManager 在 IdeaBox/Helpers/HapticManager.swift"
Task: "创建 AppearanceAdapter 在 IdeaBox/Helpers/AppearanceAdapter.swift"
Task: "创建 Color 扩展 在 IdeaBox/Extensions/Color+AppColors.swift"
```

### 批次 5: Polish (可同时执行)
```bash
# T028, T029, T030 可以并行（不同活动）
Task: "添加 SwiftUI Previews 在 IdeaBox/Views/BottomNavigationBar.swift"
Task: "更新 CHANGELOG.md"
Task: "执行 quickstart.md 验证"
```

---

## Notes (重要说明)

### TDD 规则 ⚠️
- **严格执行**: T004-T012 必须先完成且失败，才能开始 T013-T020
- **验证失败**: 每个测试运行后确认为红色（失败）
- **实现后验证**: 实现后测试应变绿色（通过）
- **不跳过测试**: 禁止使用 `XCTSkip` 或注释测试

### 并行执行标记 [P]
- [P] 表示该任务可以与同批次其他 [P] 任务并行
- 不同文件 = 可并行
- 同一文件 = 必须串行（如 T020 → T021 → T028）

### 提交策略
- 每完成一个任务提交一次
- 提交信息格式: `[T###] 任务简述`
- 例: `[T015] 实现 NavigationBarStyle 协议`

### 测试要求
- 单元测试覆盖率 ≥ 80%
- 所有公开方法有测试
- 真机测试触觉反馈和性能

### 避免事项
- ❌ 模糊任务描述
- ❌ 同一文件多个 [P] 任务
- ❌ 跳过测试直接实现
- ❌ Force unwrap (!)
- ❌ 硬编码颜色值（使用 Assets）

---

## Validation Checklist (验证清单)
*在 main() 执行期间检查*

- [x] 所有 3 个 contracts 有对应测试（T004, T005, T006）
- [x] 所有 3 个 entities 有模型任务（T013, T014, NavigationBarConfiguration 在 T015）
- [x] 所有测试在实现前（T004-T012 → T013-T021）
- [x] 并行任务真正独立（不同文件）
- [x] 每个任务指定精确文件路径
- [x] 无任务修改相同文件为 [P]（T020 和 T028 不并行）
- [x] TDD 顺序正确（红 → 绿 → 重构）

---

## Task Statistics (任务统计)

- **总任务数**: 30
- **Setup 任务**: 3 (T001-T003)
- **测试任务**: 9 (T004-T012) - 必须先失败
- **核心实现**: 9 (T013-T021)
- **集成任务**: 3 (T022-T024)
- **优化任务**: 6 (T025-T030)

**并行能力**:
- 批次 1: 2 任务并行 (T002, T003)
- 批次 2: 3 任务并行 (T004, T005, T006)
- 批次 3: 6 任务并行 (T007-T012)
- 批次 4: 6 任务并行 (T013-T016, T018, T019)
- 批次 5: 3 任务并行 (T028, T029, T030)

**最大并行度**: 6 任务

**预估时间**:
- Setup: 1 小时
- Tests: 4 小时
- Core: 8 小时
- Integration: 3 小时
- Polish: 2 小时
- **总计**: ~18 小时

---

## Progress Tracking (进度追踪)

**Phase Status**:
- [ ] Phase 3.1: Setup complete
- [ ] Phase 3.2: Tests written and failing
- [ ] Phase 3.3: Core implementation complete
- [ ] Phase 3.4: Integration complete
- [ ] Phase 3.5: Polish complete

**Completion**:
- 0/30 tasks completed
- 0% progress

---

**准备开始**: 从 T001 开始执行，严格遵循 TDD 原则！🚀

**下一步**: 执行 T001 - 验证 Xcode 项目配置

