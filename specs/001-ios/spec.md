# Feature Specification: iOS 风格周视图日历

**Feature Branch**: `001-ios`  
**Created**: 2025-10-01  
**Status**: Draft  
**Input**: 用户描述："顶部日期栏需要参考 ios 移动端的日历，横向移动的时候要移动到下一个七天，并且滚动前选的周几滚动后依旧要是周几，并且出现今天按钮，如果选中的已经是今天则隐藏今天按钮"

## Execution Flow (main)
```
1. Parse user description from Input
   → 已识别：改进顶部日历组件，采用 iOS 原生日历交互模式
2. Extract key concepts from description
   → Actors: 用户
   → Actions: 横向滑动日历、选择日期、点击"今天"按钮
   → Data: 日期、星期几、今天标识
   → Constraints: 每次滚动7天、保持星期几不变、条件显示"今天"按钮
3. For each unclear aspect:
   → [NEEDS CLARIFICATION: 滚动动画时长和缓动效果？建议使用系统标准动画]
   → [NEEDS CLARIFICATION: 是否支持快速滑动翻多周？还是只能一次翻一周？]
   → [NEEDS CLARIFICATION: 边界处理 - 可以向前/向后滚动多少周？]
4. Fill User Scenarios & Testing section
   → ✅ 主要用户流程已明确
5. Generate Functional Requirements
   → ✅ 所有需求可测试
6. Identify Key Entities (if data involved)
   → ✅ 已识别：WeekData, DayItem, DateSelection
7. Run Review Checklist
   → ⚠️ WARN "Spec has uncertainties" - 3个待澄清项
8. Return: SUCCESS (spec ready for planning after clarifications)
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

---

## 功能概述

### 背景与问题
当前日历实现采用自由横向滚动模式，用户可以连续滑动查看任意日期，但这种交互方式存在以下问题：
- 难以精确定位到特定周
- 滑动停止位置不可预测
- 缺少快速返回今天的便捷入口
- 不符合 iOS 用户的日历使用习惯

### 目标用户价值
通过采用 iOS 原生日历的交互模式，为用户提供：
- **更精确的导航**：以周为单位翻页，每次滚动范围明确
- **星期一致性**：翻周后保持相同星期几，方便查看同类型日期的活动（如每周三的会议）
- **快速回到今天**：随时可通过"今天"按钮返回当前日期
- **符合认知习惯**：与 iOS 系统日历保持一致的交互体验

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
```
作为 IdeaBox 用户
我想要像使用 iOS 系统日历那样翻页查看不同周的日期
以便我可以更高效地浏览和管理不同时间段的收藏内容
并且能快速定位到特定星期几的重复性活动
```

### Acceptance Scenarios

#### 场景 1: 向后翻周（查看下一周）
1. **Given** 用户当前选中 2025年10月2日（周四）
2. **When** 用户向左滑动日历
3. **Then** 日历翻页到下一周的周四（2025年10月9日）
4. **And** 周一到周日完整显示（10月6日-10月12日）
5. **And** 10月9日自动被选中并高亮

#### 场景 2: 向前翻周（查看上一周）
1. **Given** 用户当前选中 2025年10月2日（周四）
2. **When** 用户向右滑动日历
3. **Then** 日历翻页到上一周的周四（2025年9月25日）
4. **And** 周一到周日完整显示（9月22日-9月28日）
5. **And** 9月25日自动被选中并高亮

#### 场景 3: 点击"今天"按钮
1. **Given** 用户当前查看的是历史周（如上周三）
2. **And** "今天"按钮在底部导航栏可见
3. **When** 用户点击"今天"按钮
4. **Then** 日历跳转到包含今天的周
5. **And** 今天的日期被选中并高亮
6. **And** "今天"按钮隐藏（因为现在选中的就是今天）

#### 场景 4: 选中今天时隐藏"今天"按钮
1. **Given** 用户当前选中的日期是今天（2025年10月1日）
2. **When** 页面加载或日期更新
3. **Then** 底部导航栏的"今天"按钮不显示
4. **When** 用户翻周到其他日期（如下周三）
5. **Then** "今天"按钮重新显示

#### 场景 5: 手动选择日期
1. **Given** 日历显示当前周（10月6日-10月12日）
2. **When** 用户点击周二（10月7日）
3. **Then** 10月7日被选中并高亮
4. **And** 日历仍然显示当前周，不翻页
5. **And** 如果点击的不是今天，"今天"按钮显示

### Edge Cases

#### 边界条件
- **最早可滚动日期**：[NEEDS CLARIFICATION: 是否限制只能查看过去N周？例如过去52周]
- **最晚可滚动日期**：[NEEDS CLARIFICATION: 是否限制只能查看未来N周？例如未来52周]
- **跨年翻周**：当前周是2025年12月30日-2026年1月5日，向后翻周应正确处理跨年

#### 异常处理
- **快速连续滑动**：用户快速多次滑动时，[NEEDS CLARIFICATION: 是否支持连续翻多周？还是需要等待动画完成？]
- **网络时间不准**："今天"的判断基于设备本地时间
- **首次加载**：应用启动时，默认显示包含今天的周，今天被选中

#### 特殊日期
- **跨月翻周**：周一是3月30日，周日是4月5日，正确显示不同月份
- **闰年2月**：正确处理2月29日所在周的翻页

---

## Requirements *(mandatory)*

### Functional Requirements

#### 周视图翻页
- **FR-001**: 日历 MUST 显示完整的一周（周一到周日，共7天）
- **FR-002**: 用户 MUST 能够通过向左滑动手势翻到下一周
- **FR-003**: 用户 MUST 能够通过向右滑动手势翻到上一周
- **FR-004**: 翻周时 MUST 保持相同的星期几被选中（例如：当前周三 → 下周周三）
- **FR-005**: 翻周动画 MUST 平滑流畅，符合 iOS 原生日历的视觉效果

#### 日期选择
- **FR-006**: 用户 MUST 能够点击当前周内的任意日期进行选择
- **FR-007**: 选中的日期 MUST 以红色圆形背景高亮显示（保持现有样式）
- **FR-008**: 点击日期不触发翻周，仅更新选中状态

#### "今天"按钮
- **FR-009**: 底部导航栏 MUST 包含一个"今天"按钮
- **FR-010**: 当选中的日期不是今天时，"今天"按钮 MUST 可见
- **FR-011**: 当选中的日期是今天时，"今天"按钮 MUST 隐藏
- **FR-012**: 点击"今天"按钮时，系统 MUST 跳转到包含今天的周
- **FR-013**: 跳转到今天后，今天的日期 MUST 被选中并高亮

#### 周数据管理
- **FR-014**: 系统 MUST 自动计算并生成周数据（周一到周日）
- **FR-015**: 系统 MUST 正确处理跨月周（如3月30日-4月5日）
- **FR-016**: 系统 MUST 正确处理跨年周（如12月29日-1月4日）
- **FR-017**: 系统 MUST 标识今天所在的周和今天的日期

#### 边界与性能
- **FR-018**: 系统 MUST 限制可滚动的周数范围 [NEEDS CLARIFICATION: 建议前后各52周]
- **FR-019**: 翻周动画响应时间 MUST 小于300毫秒
- **FR-020**: 到达边界时，继续滑动 MUST 不产生错误，应有明确的反弹提示

### Non-Functional Requirements

#### 用户体验
- **NFR-001**: 交互行为 MUST 与 iOS 原生日历应用保持一致
- **NFR-002**: 滑动手势识别灵敏度 MUST 符合 iOS HIG 标准
- **NFR-003**: 翻页动画 MUST 使用系统标准缓动函数

#### 兼容性
- **NFR-004**: 功能 MUST 兼容 iOS 15.0 及以上版本
- **NFR-005**: 必须适配 iPhone 所有屏幕尺寸

#### 可维护性
- **NFR-006**: 周数据生成逻辑 MUST 与日期选择逻辑解耦
- **NFR-007**: "今天"按钮的显示/隐藏逻辑 MUST 基于响应式状态管理

---

### Key Entities

#### WeekData（周数据）
- **用途**：表示一个完整的周（7天）
- **关键属性**：
  - 周起始日期（周一）
  - 周结束日期（周日）
  - 7个 DayItem 的集合
  - 是否包含今天
  - 周偏移量（相对于今天所在周，如 -1, 0, +1）

#### DayItem（日期项）
- **用途**：表示单个日期（已存在的模型，可能需要增强）
- **关键属性**：
  - 星期几（周一、周二...周日）
  - 日期数字
  - 完整 Date 对象
  - 是否是今天
  - 是否被选中

#### DateSelection（日期选择状态）
- **用途**：管理当前选中的日期和周
- **关键属性**：
  - 当前选中的日期
  - 当前显示的周
  - 选中日期的星期几（用于翻周时保持）
  - 是否选中今天（用于控制"今天"按钮显示）

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain  
      → ⚠️ 还有3个待澄清项：
         1. 滚动动画时长和缓动效果
         2. 是否支持快速滑动翻多周
         3. 边界处理 - 可滚动周数范围
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (3个待澄清项)
- [x] User scenarios defined
- [x] Requirements generated (20个功能需求 + 7个非功能需求)
- [x] Entities identified (3个关键实体)
- [ ] Review checklist passed (待澄清项解决后通过)

---

## 建议的澄清项

在进入 `/plan` 阶段前，建议澄清以下问题：

### 1. 滚动动画参数
**问题**：翻周动画的时长和缓动效果应该是多少？  
**建议**：采用 iOS 系统标准值
- 动画时长：300ms
- 缓动函数：`easeInOut`

### 2. 快速滑动行为
**问题**：用户快速连续滑动时，是否支持一次翻多周？  
**建议**：
- **选项 A**（推荐）：每次只翻一周，快速滑动时需要等待动画完成才能继续翻页（简单、可控）
- **选项 B**：支持速度检测，快速滑动可一次翻多周（更灵活，但复杂度高）

### 3. 可滚动周数边界
**问题**：可以向前/向后查看多少周？  
**建议**：
- 向前：过去52周（1年）
- 向后：未来52周（1年）
- 到达边界时显示轻微反弹效果，不能继续滚动

---

## 与现有功能的关系

### 保留的功能
- 选中日期的红色高亮样式
- 日期下方的详细信息显示（公历+农历）
- 时间轴根据选中日期显示事件

### 修改的功能
- 日历滚动方式：从自由滚动改为按周翻页
- "今天"按钮：从固定显示改为条件显示

### 新增的功能
- 保持星期几一致的智能翻周
- "今天"按钮的动态显示/隐藏

---

**下一步**: 在澄清待定项后，运行 `/plan` 生成实施计划
