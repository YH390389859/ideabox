# Tasks: iOS 风格周视图日历

**Input**: Design documents from `/specs/001-ios/`  
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → ✅ Found: iOS 风格周视图日历实施计划
   → Extracted: Swift 5.9+, SwiftUI, TabView 分页方案
2. Load optional design documents:
   → data-model.md: 3个实体（WeekData, DayItem, DateSelection状态）
   → contracts/: 3个接口契约 + 35+测试用例
   → research.md: 6个技术决策
   → quickstart.md: 9个验证场景
3. Generate tasks by category:
   → Setup: 测试框架配置
   → Tests: 3个契约测试套件 + 集成测试
   → Core: 1个新模型 + 1个模型增强 + 3个Helper方法 + 3个视图改造
   → Integration: 状态管理整合
   → Polish: 性能测试、边界测试、文档更新
4. Apply task rules:
   → 不同文件 = [P] 并行
   → 同一文件 = 顺序（无[P]）
   → 测试优先（TDD）
5. Number tasks sequentially (T001-T024)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → ✅ 所有契约都有测试
   → ✅ 所有实体都有模型任务
   → ✅ 所有测试在实现之前
9. Return: SUCCESS (tasks ready for execution)
```

---

## Format: `[ID] [P?] Description`
- **[P]**: 可并行运行（不同文件，无依赖）
- 包含精确的文件路径

## Path Conventions
**Mobile (iOS) 项目结构**:
```
IdeaBox/
├── Models/          # 数据模型
├── Views/           # UI组件
├── Helpers/         # 工具类
└── ViewModels/      # 状态管理（可选）

IdeaBoxTests/        # 测试目录
├── Models/
├── Helpers/
└── UI/
```

---

## Phase 3.1: 环境准备

### T001: 创建测试目录结构
**描述**: 在 Xcode 项目中创建完整的测试目录结构  
**文件**: 
- `IdeaBoxTests/Models/`
- `IdeaBoxTests/Helpers/`
- `IdeaBoxTests/UI/`

**验收标准**:
- [ ] 测试目录已创建
- [ ] 已添加到 Xcode 项目
- [ ] 测试 target 配置正确

**预估时间**: 15分钟

---

## Phase 3.2: 测试优先 (TDD) ⚠️ 必须在实现前完成

**关键原则**: 这些测试必须先编写，必须失败（红色），然后才能开始实现

### T002 [P]: WeekDataProvider 契约测试
**描述**: 实现 WeekDataProvider 接口的完整测试套件  
**文件**: `IdeaBoxTests/Helpers/WeekDataProviderTests.swift`

**测试用例**（基于 contracts/WeekDataProvider.md）:
```swift
// getWeek 测试
- testGetWeekReturnsSevenDays()
- testGetWeekStartsOnMonday()
- testGetWeekEndsOnSunday()
- testGetWeekDaysAreContinuous()
- testGetWeekHandlesCrossMonth()
- testGetWeekHandlesCrossYear()
- testGetWeekNegativeOffset()
- testGetWeekPositiveOffset()

// weekOffset 测试
- testWeekOffsetSameWeekReturnsZero()
- testWeekOffsetNextWeekReturnsOne()
- testWeekOffsetLastWeekReturnsMinusOne()
- testWeekOffsetSymmetry()

// dateInWeek 测试
- testDateInWeekReturnsMonday()
- testDateInWeekReturnsSunday()
- testDateInWeekInvalidWeekdayReturnsNil()
```

**验收标准**:
- [ ] 15个测试用例全部编写
- [ ] 所有测试标记为 `XCTFail("Not implemented")`
- [ ] 测试编译通过
- [ ] 运行测试，全部失败（红色） ✅

**依赖**: T001  
**预估时间**: 1.5小时

---

### T003 [P]: DateSelectionManager 契约测试
**描述**: 实现 DateSelectionManager 接口的完整测试套件  
**文件**: `IdeaBoxTests/UI/DateSelectionManagerTests.swift`

**测试用例**（基于 contracts/DateSelectionManager.md）:
```swift
// 初始化测试
- testInitialSelectedDateIsToday()
- testInitialWeekOffsetIsZero()

// selectDate 测试
- testSelectDateUpdatesSelectedDate()
- testSelectDateDoesNotChangeWeekOffset()

// navigateToWeek 测试
- testNavigateToNextWeekUpdatesOffset()
- testNavigateToNextWeekPreservesWeekday()
- testNavigateToLastWeekPreservesWeekday()
- testNavigateToBoundaryClamps()

// jumpToToday 测试
- testJumpToTodayResetsToToday()
- testJumpToTodayFromPastWeek()

// 不变量测试
- testOffsetAlwaysInBounds()
```

**验收标准**:
- [ ] 12个测试用例全部编写
- [ ] 使用 Mock 对象模拟状态
- [ ] 所有测试失败（红色） ✅

**依赖**: T001  
**预估时间**: 1小时

---

### T004 [P]: TodayButtonController 契约测试
**描述**: 实现 TodayButtonController 接口的完整测试套件  
**文件**: `IdeaBoxTests/UI/TodayButtonControllerTests.swift`

**测试用例**（基于 contracts/TodayButtonController.md）:
```swift
// isTodaySelected 测试
- testIsTodaySelectedReturnsTrueWhenToday()
- testIsTodaySelectedReturnsFalseWhenYesterday()
- testIsTodaySelectedReturnsFalseWhenTomorrow()
- testIsTodaySelectedHandlesSameDay()

// shouldShowTodayButton 测试
- testShouldShowTodayButtonHiddenWhenToday()
- testShouldShowTodayButtonVisibleWhenNotToday()
- testShouldShowTodayButtonVisibleInPast()
- testShouldShowTodayButtonVisibleInFuture()

// 集成测试
- testButtonStateChangesWithDateSelection()
```

**验收标准**:
- [ ] 9个测试用例全部编写
- [ ] 包含 MockController 实现
- [ ] 所有测试失败（红色） ✅

**依赖**: T001  
**预估时间**: 45分钟

---

### T005 [P]: WeekData 模型单元测试
**描述**: 为 WeekData 模型编写单元测试  
**文件**: `IdeaBoxTests/Models/WeekDataTests.swift`

**测试用例**:
```swift
- testWeekDataContainsSevenDays()
- testWeekDataContainsToday()
- testWeekDataDateForWeekday()
- testWeekDataEquality()
- testWeekDataValidation()
```

**验收标准**:
- [ ] 5个测试用例编写
- [ ] 测试 WeekData 的计算属性
- [ ] 所有测试失败（红色） ✅

**依赖**: T001  
**预估时间**: 30分钟

---

### T006 [P]: DayItem 增强单元测试
**描述**: 为 DayItem 的新增 weekdayIndex 属性编写测试  
**文件**: `IdeaBoxTests/Models/DayItemTests.swift`

**测试用例**:
```swift
- testDayItemWeekdayIndexRange()
- testDayItemWeekdayIndexConsistency()
- testDayItemEquality()
```

**验收标准**:
- [ ] 3个测试用例编写
- [ ] 验证 weekdayIndex 在 1-7 范围内
- [ ] 所有测试失败（红色） ✅

**依赖**: T001  
**预估时间**: 20分钟

---

## Phase 3.3: 核心实现（仅在测试失败后）

**前置条件**: T002-T006 全部完成且失败（红色阶段）

### T007 [P]: 创建 WeekData 模型
**描述**: 实现 WeekData 数据模型  
**文件**: `IdeaBox/Models/WeekData.swift`

**实现内容**:
```swift
struct WeekData: Identifiable, Equatable {
    let id: UUID
    let offset: Int
    let monday: Date
    let sunday: Date
    let days: [DayItem]
    
    var containsToday: Bool { /* ... */ }
    func date(for weekday: Int) -> Date? { /* ... */ }
    static func == (lhs: WeekData, rhs: WeekData) -> Bool { /* ... */ }
}
```

**验收标准**:
- [ ] 所有属性已定义
- [ ] 计算属性实现
- [ ] `containsToday` 逻辑正确
- [ ] `date(for:)` 方法正确
- [ ] T005 测试通过（绿色） ✅

**依赖**: T005（测试先行）  
**预估时间**: 30分钟

---

### T008 [P]: 增强 DayItem 模型
**描述**: 为 DayItem 添加 weekdayIndex 属性  
**文件**: `IdeaBox/Models/DayItem.swift`

**修改内容**:
```swift
struct DayItem: Identifiable, Equatable {
    // 现有属性...
    let weekdayIndex: Int  // 新增：1-7 (1=周一)
}
```

**验收标准**:
- [ ] `weekdayIndex` 属性已添加
- [ ] 不破坏现有功能
- [ ] T006 测试通过（绿色） ✅

**依赖**: T006  
**预估时间**: 15分钟

---

### T009: 扩展 DateHelper - 添加周计算方法
**描述**: 在 DateHelper 中实现周相关的计算方法  
**文件**: `IdeaBox/Helpers/DateHelper.swift`

**新增方法**（基于 data-model.md）:
```swift
extension DateHelper {
    func getMonday(for date: Date) -> Date
    func getWeek(offset: Int, relativeTo baseDate: Date) -> WeekData
    func weekOffset(for date: Date, relativeTo baseDate: Date) -> Int
    func dateInWeek(_ weekData: WeekData, weekday: Int) -> Date?
}
```

**验收标准**:
- [ ] 4个方法全部实现
- [ ] 正确处理跨月边界（3月31日→4月6日）
- [ ] 正确处理跨年边界（12月29日→1月4日）
- [ ] T002 测试通过（绿色） ✅

**依赖**: T002, T007（需要 WeekData）  
**预估时间**: 2小时

---

### T010: 重构 WeekCalendarView - 实现分页滚动
**描述**: 将自由滚动改为 TabView 分页模式  
**文件**: `IdeaBox/Views/WeekCalendarView.swift`

**实现内容**:
```swift
struct WeekCalendarView: View {
    @State private var currentWeekOffset: Int = 0
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    var body: some View {
        TabView(selection: $currentWeekOffset) {
            ForEach(-52...52, id: \.self) { offset in
                WeekView(week: dateHelper.getWeek(offset: offset))
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear { scrollToCurrentWeek() }
    }
}
```

**关键功能**:
1. 使用 TabView 实现分页
2. 周偏移量范围：[-52, 52]
3. 初始定位到今天所在周
4. 手势识别和动画（300ms）

**验收标准**:
- [ ] 左滑翻到下一周
- [ ] 右滑翻到上一周
- [ ] 动画流畅（约300ms）
- [ ] 边界处理（52周限制）
- [ ] 不破坏现有日期选择功能

**依赖**: T009（需要 getWeek 方法）  
**预估时间**: 3小时

---

### T011: 实现星期几保持逻辑
**描述**: 翻周时自动选中新周的同一星期几  
**文件**: `IdeaBox/Views/WeekCalendarView.swift` (继续 T010)

**实现内容**:
```swift
.onChange(of: currentWeekOffset) { newOffset in
    let weekday = Calendar.current.component(.weekday, from: selectedDate)
    let newWeek = dateHelper.getWeek(offset: newOffset)
    if let newDate = newWeek.days.first(where: { 
        Calendar.current.component(.weekday, from: $0.date) == weekday 
    }) {
        selectedDate = newDate.date
    }
}
```

**验收标准**:
- [ ] 翻周后自动选中对应星期几
- [ ] 从周三翻到下周，自动选中下周三
- [ ] 从周日翻到上周，自动选中上周日
- [ ] Quickstart 场景 1-2 通过 ✅

**依赖**: T010  
**预估时间**: 1小时

---

### T012: 改造 BottomNavigationBar - 今天按钮条件显示
**描述**: 实现"今天"按钮的智能显示/隐藏逻辑  
**文件**: `IdeaBox/Views/BottomNavigationBar.swift`

**实现内容**:
```swift
struct BottomNavigationBar: View {
    @Binding var selectedDate: Date
    let onTodayTapped: () -> Void
    
    private var isTodaySelected: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var shouldShowTodayButton: Bool {
        !isTodaySelected
    }
    
    var body: some View {
        HStack {
            if shouldShowTodayButton {
                Button(action: onTodayTapped) {
                    Text("今天")
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "007AFF"))
                }
                .transition(.opacity)
            }
            // ... 其他按钮
        }
        .animation(.easeInOut(duration: 0.2), value: shouldShowTodayButton)
    }
}
```

**验收标准**:
- [ ] 选中今天时按钮隐藏
- [ ] 选中其他日期时按钮显示
- [ ] 显示/隐藏带有平滑动画
- [ ] T003, T004 测试通过（绿色） ✅
- [ ] Quickstart 场景 4 通过 ✅

**依赖**: T003, T004  
**预估时间**: 1小时

---

### T013: 更新 ContentView - 整合周导航状态
**描述**: 在 ContentView 中整合新的周导航逻辑  
**文件**: `IdeaBox/ContentView.swift`

**修改内容**:
```swift
struct ContentView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentWeekOffset: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                WeekCalendarView(
                    currentWeekOffset: $currentWeekOffset,
                    selectedDate: $selectedDate,
                    onDateSelected: { date in
                        selectedDate = date
                    }
                )
                
                DateHeaderView(selectedDate: selectedDate)
                TimelineView(events: events)
                
                Spacer()
            }
            
            BottomNavigationBar(
                selectedDate: $selectedDate,
                onTodayTapped: {
                    jumpToToday()
                }
            )
        }
    }
    
    private func jumpToToday() {
        selectedDate = Date()
        currentWeekOffset = 0
    }
}
```

**验收标准**:
- [ ] 状态管理正确
- [ ] 日期选择和周导航同步
- [ ] "今天"按钮功能正常
- [ ] 不破坏现有时间轴功能
- [ ] Quickstart 场景 3, 5 通过 ✅

**依赖**: T010, T011, T012  
**预估时间**: 1小时

---

## Phase 3.4: 集成测试

### T014 [P]: 完整翻周场景集成测试
**描述**: 验证完整的翻周用户流程  
**文件**: `IdeaBoxTests/UI/WeekNavigationIntegrationTests.swift`

**测试场景**:
```swift
- testNavigateToNextWeekAndPreserveWeekday()
- testNavigateToPreviousWeekAndPreserveWeekday()
- testMultipleWeekNavigation()
- testNavigationToBoundary()
```

**验收标准**:
- [ ] 4个集成测试通过
- [ ] Quickstart 场景 1, 2, 8 通过 ✅

**依赖**: T011, T013  
**预估时间**: 1小时

---

### T015 [P]: "今天"按钮交互集成测试
**描述**: 验证"今天"按钮的完整交互流程  
**文件**: `IdeaBoxTests/UI/TodayButtonIntegrationTests.swift`

**测试场景**:
```swift
- testTodayButtonHiddenWhenSelectingToday()
- testTodayButtonShownWhenNavigatingAway()
- testTodayButtonJumpsBackToToday()
- testTodayButtonAnimationSmooth()
```

**验收标准**:
- [ ] 4个集成测试通过
- [ ] Quickstart 场景 4, 5 通过 ✅

**依赖**: T012, T013  
**预估时间**: 45分钟

---

### T016: 边界情况测试
**描述**: 测试跨月、跨年、边界限制等特殊情况  
**文件**: 扩展 `IdeaBoxTests/Helpers/WeekDataProviderTests.swift`

**新增测试**:
```swift
- testCrossMonthWeek_March31ToApril6()
- testCrossYearWeek_Dec29ToJan4()
- testLeapYearFebruary()
- testBoundaryAt52WeeksForward()
- testBoundaryAt52WeeksBackward()
- testBounceEffectAtBoundary()
```

**验收标准**:
- [ ] 6个边界测试通过
- [ ] Quickstart 场景 6, 7, 8 通过 ✅

**依赖**: T009, T010  
**预估时间**: 1.5小时

---

### T017: 快速滑动性能测试
**描述**: 验证快速连续滑动的性能和正确性  
**文件**: `IdeaBoxTests/UI/PerformanceTests.swift`

**测试内容**:
```swift
- testQuickSwipePerformance()
- testAnimationDuration()
- testMemoryUsageDuringNavigation()
- testNoFrameDrops()
```

**验收标准**:
- [ ] 翻页动画 < 300ms
- [ ] 快速滑动无卡顿
- [ ] 内存占用稳定（< 5MB增量）
- [ ] Quickstart 场景 9 通过 ✅

**依赖**: T010, T011  
**预估时间**: 1小时

---

## Phase 3.5: 优化与文档

### T018 [P]: 代码审查和重构
**描述**: 清理代码，优化性能，移除重复逻辑

**检查项**:
- [ ] 移除未使用的代码和注释
- [ ] 优化周数据生成算法
- [ ] 统一命名规范
- [ ] 添加必要的文档注释
- [ ] 检查内存泄漏（Instruments）

**验收标准**:
- [ ] SwiftLint 通过（0 warnings）
- [ ] 代码覆盖率 > 80%
- [ ] 无明显性能问题

**依赖**: T001-T017 全部完成  
**预估时间**: 2小时

---

### T019 [P]: 更新项目文档
**描述**: 更新 README 和 CHANGELOG

**文件**:
- `README.md`
- `CHANGELOG.md`

**更新内容**:
```markdown
### README.md
- 更新功能特性（iOS风格周视图）
- 更新使用说明（翻周操作、今天按钮）

### CHANGELOG.md
- 记录新功能：按周翻页、星期几保持、今天按钮
- 记录技术改进：TabView分页、周数据管理
```

**验收标准**:
- [ ] README 准确描述新功能
- [ ] CHANGELOG 记录完整
- [ ] 截图更新（可选）

**依赖**: T018  
**预估时间**: 30分钟

---

### T020: 运行完整验收测试
**描述**: 按照 quickstart.md 执行完整的手动验收测试

**文件**: `specs/001-ios/quickstart.md`

**验收场景**:
1. ✅ 向后翻周并保持星期几
2. ✅ 向前翻周并保持星期几
3. ✅ 手动选择日期（不翻页）
4. ✅ "今天"按钮智能显示
5. ✅ 点击"今天"按钮跳转
6. ✅ 跨月翻周验证
7. ✅ 跨年翻周验证
8. ✅ 边界限制验证
9. ✅ 快速连续滑动

**验收标准**:
- [ ] 所有9个场景通过
- [ ] 性能指标达标（60fps, <300ms）
- [ ] 无回归问题

**依赖**: T001-T019 全部完成  
**预估时间**: 15分钟

---

### T021: 创建发布准备清单
**描述**: 准备功能发布的最终检查清单

**检查项**:
- [ ] 所有单元测试通过
- [ ] 所有集成测试通过
- [ ] 所有 UI 测试通过
- [ ] Quickstart 验收通过
- [ ] 代码审查完成
- [ ] 文档更新完成
- [ ] 无已知 bug
- [ ] 性能达标

**验收标准**:
- [ ] 清单全部勾选 ✅
- [ ] 准备合并到主分支

**依赖**: T020  
**预估时间**: 15分钟

---

## 依赖关系图

```
Setup
  T001 (测试目录) 
    ↓
Tests (TDD 红阶段)
  T002 [P] (WeekDataProvider测试)
  T003 [P] (DateSelectionManager测试)
  T004 [P] (TodayButtonController测试)
  T005 [P] (WeekData测试)
  T006 [P] (DayItem测试)
    ↓
Core Implementation (TDD 绿阶段)
  T007 [P] (WeekData模型)         ← T005
  T008 [P] (DayItem增强)          ← T006
  T009 (DateHelper扩展)           ← T002, T007
    ↓
  T010 (WeekCalendarView重构)    ← T009
    ↓
  T011 (星期几保持逻辑)           ← T010
    ↓
  T012 [P] (BottomNavigationBar) ← T003, T004
  T013 (ContentView整合)          ← T010, T011, T012
    ↓
Integration Tests
  T014 [P] (翻周集成测试)         ← T011, T013
  T015 [P] (今天按钮集成测试)     ← T012, T013
  T016 (边界情况测试)            ← T009, T010
  T017 (性能测试)                ← T010, T011
    ↓
Polish
  T018 [P] (代码审查)            ← All above
  T019 [P] (文档更新)            ← T018
  T020 (验收测试)                ← T019
  T021 (发布清单)                ← T020
```

---

## 并行执行示例

### 批次 1: 测试编写（TDD 红阶段）
```bash
# 可同时执行 T002-T006（不同文件）
Task T002: "实现 WeekDataProviderTests.swift 的15个测试用例"
Task T003: "实现 DateSelectionManagerTests.swift 的12个测试用例"
Task T004: "实现 TodayButtonControllerTests.swift 的9个测试用例"
Task T005: "实现 WeekDataTests.swift 的5个测试用例"
Task T006: "实现 DayItemTests.swift 的3个测试用例"
```

### 批次 2: 模型实现（TDD 绿阶段）
```bash
# 可同时执行 T007-T008（不同文件）
Task T007: "创建 WeekData.swift 模型，使 T005 通过"
Task T008: "增强 DayItem.swift，添加 weekdayIndex，使 T006 通过"
```

### 批次 3: 集成测试
```bash
# 可同时执行 T014-T015（不同文件）
Task T014: "编写翻周集成测试 WeekNavigationIntegrationTests.swift"
Task T015: "编写今天按钮集成测试 TodayButtonIntegrationTests.swift"
```

### 批次 4: 最终优化
```bash
# 可同时执行 T018-T019（不同文件）
Task T018: "代码审查、重构、性能优化"
Task T019: "更新 README.md 和 CHANGELOG.md"
```

---

## 任务统计

### 按阶段
- **Setup**: 1个任务
- **Tests**: 5个任务（全部 [P]）
- **Core**: 7个任务（2个 [P]）
- **Integration**: 4个任务（2个 [P]）
- **Polish**: 4个任务（2个 [P]）

**总计**: 21个任务

### 按并行性
- **可并行 [P]**: 11个任务
- **顺序执行**: 10个任务

### 预估工时
- **测试编写**: 4小时
- **核心实现**: 7.75小时
- **集成测试**: 4.25小时
- **优化文档**: 3小时

**总计**: 约 19 小时 ≈ **2-3个工作日**

---

## 验证清单

### ✅ 所有契约都有对应测试
- [x] WeekDataProvider → T002
- [x] DateSelectionManager → T003
- [x] TodayButtonController → T004

### ✅ 所有实体都有模型任务
- [x] WeekData → T007
- [x] DayItem (增强) → T008
- [x] DateSelection (状态) → T013

### ✅ 所有测试都在实现之前
- [x] T002-T006 在 T007-T013 之前

### ✅ 并行任务真正独立
- [x] T002-T006: 不同测试文件 ✅
- [x] T007-T008: 不同模型文件 ✅
- [x] T014-T015: 不同集成测试文件 ✅
- [x] T018-T019: 代码 vs 文档 ✅

### ✅ 每个任务指定了精确文件路径
- [x] 所有任务都包含明确的文件路径

### ✅ 无同文件并行冲突
- [x] 同一文件的任务按顺序排列（如 T010→T011）

---

## 注意事项

### TDD 流程
1. **红色阶段** (T002-T006): 编写测试，运行失败 ✅
2. **绿色阶段** (T007-T013): 实现代码，使测试通过 ✅
3. **重构阶段** (T018): 优化代码，保持测试通过 ✅

### 提交策略
- 每完成一个任务后提交
- 提交信息格式：`[T001] 创建测试目录结构`
- 确保每次提交测试都通过

### 性能监控
- 使用 Xcode Instruments 监控性能
- Time Profiler: 验证 60fps
- Allocations: 检查内存泄漏
- Leaks: 检测循环引用

### 避免的陷阱
- ❌ 不要跳过测试直接实现
- ❌ 不要在测试失败前修改实现代码
- ❌ 不要同时修改同一文件（破坏并行）
- ❌ 不要忽略边界情况测试

---

## 成功标准

### ✅ 功能完整性
- [ ] 所有20个功能需求（FR-001 ~ FR-020）已实现
- [ ] 所有7个非功能需求（NFR-001 ~ NFR-007）已满足
- [ ] 9个 Quickstart 场景全部通过

### ✅ 质量指标
- [ ] 单元测试覆盖率 > 80%
- [ ] 所有测试通过（0 failures）
- [ ] SwiftLint 0 warnings
- [ ] 性能达标（60fps, <300ms, <5MB）

### ✅ 交付物
- [ ] 可运行的 iOS 应用
- [ ] 完整的测试套件
- [ ] 更新的文档（README, CHANGELOG）
- [ ] 通过的验收测试

---

**任务清单生成于**: 2025-10-01  
**Feature Branch**: `001-ios`  
**Ready for execution**: ✅ 是

**下一步**: 开始执行 T001，创建测试目录结构

