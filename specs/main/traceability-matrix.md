# 需求追溯矩阵

**项目**: 收藏日历 IdeaBox  
**版本**: 1.0.0  
**最后更新**: 2025-10-01

---

## 矩阵说明

本文档建立需求与实现代码之间的双向追溯关系，确保：
- 每个需求都有对应的实现
- 每个实现都可追溯到需求
- 便于影响分析和回归测试

### 图例
- ✅ 已完整实现
- 🔶 部分实现
- ❌ 未实现
- 📄 需求文档
- 💾 数据模型
- 🎨 视图组件
- 🛠️ 工具类

---

## 功能需求追溯矩阵

| 需求ID | 需求名称 | 状态 | 实现文件 | 关键函数/组件 | 测试用例 | 备注 |
|--------|---------|------|---------|--------------|---------|------|
| **FR-001** | 横向滚动日历 | ✅ | WeekCalendarView.swift | ScrollView(.horizontal) | - | 121天日期数据 |
| | | | DateHelper.swift | getExtendedDays() | - | |
| **FR-002** | 日期选择与高亮 | ✅ | WeekCalendarView.swift | Button(action:), isSelected | - | 红色高亮 |
| | | | ContentView.swift | selectedDate @State | - | |
| **FR-003** | 自动滚动定位 | ✅ | WeekCalendarView.swift | scrollToSelectedDate() | - | ScrollViewReader |
| | | | | .onChange(of: selectedDate) | - | |
| **FR-004** | 日期信息显示 | ✅ | DateHeaderView.swift | formatDateHeader() | - | 公历+农历 |
| | | | DateHelper.swift | getLunarDate() | - | 简化版本 |
| **FR-005** | 24小时时间轴 | ✅ | TimelineView.swift | timeSlots array | - | 00:00-23:00 |
| | | | TimeSlotRow.swift | HStack(时间+事件) | - | |
| **FR-006** | 智能高度调整 | ✅ | TimeSlotRow.swift | rowHeight computed | - | 动态计算 |
| | | | | eventsForHour() | - | |
| **FR-007** | 事件卡片显示 | ✅ | TimelineView.swift | EventCard struct | - | 72px高度 |
| | | | EventItem.swift | backgroundColor等属性 | - | |
| **FR-008** | 多种事件类型支持 | ✅ | EventItem.swift | EventType enum | - | 3种类型 |
| | | | | EventItem struct | - | |
| **FR-009** | 时间轴自动定位 | ✅ | TimelineView.swift | .onAppear, scrollTo() | - | 定位到8点 |
| | | | | ScrollViewReader | - | |
| **FR-010** | 底部导航栏 | ✅ | BottomNavigationBar.swift | HStack(3按钮) | - | 今天/添加/我的 |
| | | | ContentView.swift | onTodayTapped callback | - | |

---

## 非功能需求追溯矩阵

| 需求ID | 需求名称 | 状态 | 实现方式 | 验证方法 | 指标 |
|--------|---------|------|---------|---------|------|
| **NFR-001** | 性能要求 | ✅ | SwiftUI原生优化 | 性能测试 | 60fps |
| | | | 异步加载 | Instruments分析 | < 100ms响应 |
| **NFR-002** | 兼容性要求 | ✅ | Info.plist配置 | 设备测试 | iOS 15.0+ |
| | | | 自适应布局 | 模拟器测试 | iPhone/iPad |
| **NFR-003** | 可维护性要求 | ✅ | MVVM架构 | 代码审查 | 模块分离 |
| | | | 目录结构规范 | 文档完整性 | 3层目录 |
| **NFR-004** | 可扩展性要求 | ✅ | 枚举+协议设计 | 扩展测试 | 易添加类型 |
| | | | 参数化配置 | - | 可配置 |
| **NFR-005** | 用户体验要求 | ✅ | HIG遵循 | 用户测试 | iOS标准 |
| | | | 动画效果 | 视觉检查 | 流畅自然 |

---

## 用户故事追溯矩阵

| 故事ID | 用户故事 | 相关需求 | 实现文件 | 验收状态 |
|--------|---------|---------|---------|---------|
| **US-001** | 查看今天的收藏 | FR-003, FR-009 | ContentView.swift<br/>TimelineView.swift | ✅ 已验收 |
| **US-002** | 浏览历史收藏 | FR-001, FR-002 | WeekCalendarView.swift<br/>DateHelper.swift | ✅ 已验收 |
| **US-003** | 在时间轴上查看事件 | FR-005, FR-006, FR-007 | TimelineView.swift<br/>TimeSlotRow.swift | ✅ 已验收 |
| **US-004** | 快速返回今天 | FR-010, FR-003 | BottomNavigationBar.swift<br/>ContentView.swift | ✅ 已验收 |

---

## 数据模型追溯矩阵

| 模型 | 文件位置 | 相关需求 | 属性列表 | 使用位置 |
|------|---------|---------|---------|---------|
| **DayItem** | Models/DayItem.swift | FR-001, FR-002 | id, weekday, day, date, isToday | WeekCalendarView<br/>DateHelper<br/>ContentView |
| **EventItem** | Models/EventItem.swift | FR-007, FR-008 | id, type, time, title, subtitle, backgroundColor, borderColor, accentColor, logoColor | TimelineView<br/>EventCard<br/>ContentView |
| **EventType** | Models/EventItem.swift | FR-008 | link, textDiary, voiceDiary | EventItem |

---

## 视图组件追溯矩阵

| 组件 | 文件位置 | 相关需求 | 父组件 | 子组件 | 职责 |
|------|---------|---------|--------|--------|------|
| **ContentView** | ContentView.swift | FR-001~FR-010 | IdeaBoxApp | WeekCalendarView<br/>DateHeaderView<br/>TimelineView<br/>BottomNavigationBar | 主视图协调器 |
| **WeekCalendarView** | Views/WeekCalendarView.swift | FR-001, FR-002, FR-003 | ContentView | - | 横向滚动日历 |
| **DateHeaderView** | Views/DateHeaderView.swift | FR-004 | ContentView | - | 日期信息显示 |
| **TimelineView** | Views/TimelineView.swift | FR-005, FR-009 | ContentView | TimeSlotRow<br/>EventCard | 24小时时间轴容器 |
| **TimeSlotRow** | Views/TimelineView.swift | FR-005, FR-006 | TimelineView | EventCard | 单个时间段行 |
| **EventCard** | Views/TimelineView.swift | FR-007, FR-008 | TimeSlotRow | - | 事件卡片展示 |
| **BottomNavigationBar** | Views/BottomNavigationBar.swift | FR-010 | ContentView | - | 底部导航 |

---

## 工具类追溯矩阵

| 工具类 | 文件位置 | 相关需求 | 提供功能 | 被调用处 |
|--------|---------|---------|---------|---------|
| **DateHelper** | Helpers/DateHelper.swift | FR-001, FR-004 | getWeekDays()<br/>getExtendedDays()<br/>formatDateHeader()<br/>getLunarDate()<br/>isToday() | ContentView<br/>WeekCalendarView<br/>DateHeaderView |

---

## 代码到需求反向追溯

### IdeaBox/IdeaBoxApp.swift
- **作用**: 应用入口点
- **相关需求**: 整体应用架构
- **关键代码**:
  ```swift
  @main
  struct IdeaBoxApp: App {
      var body: some Scene {
          WindowGroup {
              ContentView()
          }
      }
  }
  ```

### IdeaBox/ContentView.swift
- **相关需求**: FR-001, FR-002, FR-003, FR-004, FR-005, FR-010
- **关键状态**:
  - `selectedDate`: 当前选中日期 → FR-002
  - `weekDays`: 日期数据列表 → FR-001
- **关键方法**:
  - `updateWeekDays()`: 更新日期列表 → FR-001
  - `onTodayTapped()`: 今天按钮回调 → FR-010

### IdeaBox/Models/DayItem.swift
- **相关需求**: FR-001, FR-002
- **数据结构**:
  ```swift
  struct DayItem: Identifiable, Equatable {
      let id: UUID
      let weekday: String    // FR-001
      let day: Int           // FR-001
      let date: Date         // FR-002
      let isToday: Bool      // FR-002
  }
  ```

### IdeaBox/Models/EventItem.swift
- **相关需求**: FR-007, FR-008
- **类型枚举**: EventType → FR-008
- **数据结构**: EventItem → FR-007

### IdeaBox/Views/WeekCalendarView.swift
- **相关需求**: FR-001, FR-002, FR-003
- **关键组件**:
  - `ScrollView(.horizontal)` → FR-001
  - `Button(action:)` → FR-002
  - `ScrollViewReader` → FR-003
- **关键方法**:
  - `scrollToSelectedDate()` → FR-003

### IdeaBox/Views/DateHeaderView.swift
- **相关需求**: FR-004
- **关键代码**:
  - `formatDateHeader()` → 公历显示
  - `getLunarDate()` → 农历显示

### IdeaBox/Views/TimelineView.swift
- **相关需求**: FR-005, FR-006, FR-007, FR-009
- **关键组件**:
  - `TimelineView` → FR-005, FR-009
  - `TimeSlotRow` → FR-005, FR-006
  - `EventCard` → FR-007
- **关键数组**:
  - `timeSlots` → FR-005 (24小时)

### IdeaBox/Views/BottomNavigationBar.swift
- **相关需求**: FR-010
- **按钮**:
  - "今天" 按钮 → FR-010
  - "添加" 按钮 → 预留功能
  - "我的" 按钮 → 预留功能

### IdeaBox/Helpers/DateHelper.swift
- **相关需求**: FR-001, FR-004
- **关键方法**:
  - `getExtendedDays()` → FR-001 (121天数据)
  - `formatDateHeader()` → FR-004 (格式化显示)
  - `getLunarDate()` → FR-004 (农历转换)

---

## 测试覆盖率矩阵

### 当前测试状态

| 类别 | 测试文件 | 覆盖的需求 | 测试用例数 | 状态 |
|------|---------|-----------|-----------|------|
| 单元测试 | - | - | 0 | ❌ 未创建 |
| 集成测试 | - | - | 0 | ❌ 未创建 |
| UI测试 | - | - | 0 | ❌ 未创建 |

### 建议的测试覆盖

#### 单元测试 (Models & Helpers)
| 测试类 | 测试目标 | 覆盖需求 | 优先级 |
|--------|---------|---------|--------|
| DayItemTests | DayItem模型 | FR-001, FR-002 | P0 |
| EventItemTests | EventItem模型 | FR-007, FR-008 | P0 |
| DateHelperTests | 日期计算逻辑 | FR-001, FR-004 | P0 |

#### UI测试 (Views)
| 测试类 | 测试目标 | 覆盖需求 | 优先级 |
|--------|---------|---------|--------|
| WeekCalendarViewTests | 日历滚动和选择 | FR-001, FR-002, FR-003 | P1 |
| TimelineViewTests | 时间轴显示 | FR-005, FR-006, FR-007 | P1 |
| BottomNavigationBarTests | 导航功能 | FR-010 | P1 |

---

## 变更影响分析

### 如果修改 DayItem 模型
**影响范围**:
- ✋ WeekCalendarView.swift (显示逻辑)
- ✋ DateHelper.swift (数据生成)
- ✋ ContentView.swift (数据使用)

**影响需求**: FR-001, FR-002, FR-003

---

### 如果修改 EventItem 模型
**影响范围**:
- ✋ EventCard (视图渲染)
- ✋ TimeSlotRow (事件列表)
- ✋ ContentView (示例数据)

**影响需求**: FR-007, FR-008

---

### 如果修改时间轴布局算法
**影响范围**:
- ✋ TimeSlotRow.swift (高度计算)
- ✋ TimelineView.swift (整体布局)

**影响需求**: FR-005, FR-006

---

## 缺失分析

### 未实现的需求
根据 CHANGELOG 和 README，以下功能计划中但未实现：

| 功能 | 计划版本 | 相关需求 | 优先级 |
|------|---------|---------|--------|
| 添加事件功能 | v1.1.0 | 新需求 | P0 |
| 事件编辑删除 | v1.2.0 | 新需求 | P1 |
| 数据持久化 | v1.1.0 | NFR-新增 | P0 |
| 云同步 | v1.3.0 | NFR-新增 | P2 |
| 搜索筛选 | v1.2.0 | 新需求 | P2 |

### 测试空白
- ❌ 所有需求都缺少自动化测试
- ❌ 未建立 CI/CD 流程
- ❌ 未进行性能基准测试

### 文档空白
- ✅ 功能规范已补全 (本文档)
- ✅ 需求追溯已建立 (本文档)
- ❌ 缺少 API 文档注释
- ❌ 缺少架构决策记录 (ADR)

---

## 版本追溯

| 版本 | 日期 | 新增需求 | 修改需求 | 影响文件 |
|------|------|---------|---------|---------|
| 1.0.0 | 2025-10-01 | FR-001~FR-010<br/>NFR-001~NFR-005 | - | 所有文件 |

---

## 附录：快速查找

### 按文件查找需求
```
ContentView.swift          → FR-001, FR-002, FR-003, FR-010
WeekCalendarView.swift     → FR-001, FR-002, FR-003
DateHeaderView.swift       → FR-004
TimelineView.swift         → FR-005, FR-006, FR-007, FR-008, FR-009
BottomNavigationBar.swift  → FR-010
DayItem.swift             → FR-001, FR-002
EventItem.swift           → FR-007, FR-008
DateHelper.swift          → FR-001, FR-004
```

### 按需求查找文件
```
FR-001 → WeekCalendarView, DateHelper, ContentView
FR-002 → WeekCalendarView, ContentView, DayItem
FR-003 → WeekCalendarView, ContentView
FR-004 → DateHeaderView, DateHelper
FR-005 → TimelineView, TimeSlotRow
FR-006 → TimeSlotRow
FR-007 → EventCard, EventItem
FR-008 → EventItem
FR-009 → TimelineView
FR-010 → BottomNavigationBar, ContentView
```

---

**文档版本**: 1.0.0  
**生成日期**: 2025-10-01  
**维护者**: IdeaBox Team  
**下次更新**: 当需求或实现发生变更时

