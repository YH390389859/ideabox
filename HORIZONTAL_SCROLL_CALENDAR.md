# 横向滚动日历功能

## 功能概述

顶部日历条现在支持横向滚动，用户可以左右滑动查看前后共121天的日期。

## 技术实现

### 1. 数据层扩展

#### DateHelper 新增方法
```swift
func getExtendedDays(
    centerDate: Date = Date(), 
    daysBefore: Int = 60, 
    daysAfter: Int = 60
) -> [DayItem]
```

**参数说明**：
- `centerDate`: 中心日期（通常是当前选中的日期）
- `daysBefore`: 中心日期之前的天数（默认60天）
- `daysAfter`: 中心日期之后的天数（默认60天）

**返回**：共 121 个 DayItem（60 + 1 + 60）

### 2. UI层改造

#### WeekCalendarView 架构

```swift
ScrollViewReader { proxy in
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            ForEach(days) { day in
                // 日期按钮
                Button { ... }
                    .id(day.id)  // 关键：为每个日期添加ID
            }
        }
    }
    .onAppear {
        // 自动滚动到选中日期
        scrollToSelectedDate(proxy: proxy)
    }
    .onChange(of: selectedDate) {
        // 日期变化时自动滚动
        scrollToSelectedDate(proxy: proxy)
    }
}
```

### 3. 自动定位功能

#### 滚动逻辑
```swift
private func scrollToSelectedDate(proxy: ScrollViewProxy) {
    if let selectedDay = days.first(where: { 
        Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
    }) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo(selectedDay.id, anchor: .center)
            }
        }
    }
}
```

**触发时机**：
- ✅ 视图首次加载（`onAppear`）
- ✅ 选中日期变化（`onChange`）
- ✅ 点击日期按钮

## 用户体验

### 滚动交互

```
← 向左滑动 ─────────────────────── 向右滑动 →

[...] [28] [29] [30] [1] [2] [3] [4] [...]
              ↑
           选中日期（自动居中）
```

### 视觉反馈

1. **选中状态**：红色圆形背景 (#FF453B)
2. **普通状态**：透明背景
3. **平滑动画**：滚动和切换都有动画效果
4. **无滚动条**：`showsIndicators: false` 保持界面简洁

### 交互流程

```
用户操作                    系统响应
────────────────────────────────────────
打开应用          →         自动滚动到今天
                           （居中显示）

左右滑动          →         流畅滚动
                           查看前后日期

点击某个日期      →         1. 切换到该日期
                           2. 自动居中该日期
                           3. 更新下方内容

点击"今天"按钮    →         1. 回到今天
                           2. 自动滚动到今天
                           3. 居中显示
```

## 性能优化

### 1. 数据量控制
- 只生成 121 天数据（约 4 个月）
- 避免一次性加载过多数据

### 2. 延迟滚动
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    // 确保视图已完全加载再滚动
}
```

### 3. ID 复用
- 使用 `DayItem` 的 `id` 属性
- SwiftUI 自动优化渲染

## 代码示例

### ContentView 中使用
```swift
@State private var weekDays: [DayItem] = []

private func updateWeekDays() {
    // 获取前后60天，共121天
    weekDays = dateHelper.getExtendedDays(
        centerDate: selectedDate, 
        daysBefore: 60, 
        daysAfter: 60
    )
}
```

### WeekCalendarView 调用
```swift
WeekCalendarView(
    days: weekDays,
    selectedDate: $selectedDate,
    onDateSelected: { date in
        selectedDate = date
    }
)
```

## 扩展性

### 调整显示范围

如果需要显示更多天数，只需修改参数：

```swift
// 显示前后90天（共181天）
weekDays = dateHelper.getExtendedDays(
    centerDate: selectedDate,
    daysBefore: 90,
    daysAfter: 90
)
```

### 自定义滚动锚点

如果想改变滚动位置，修改 `anchor` 参数：

```swift
// 居中显示
proxy.scrollTo(selectedDay.id, anchor: .center)

// 靠左显示
proxy.scrollTo(selectedDay.id, anchor: .leading)

// 靠右显示
proxy.scrollTo(selectedDay.id, anchor: .trailing)
```

## 优势

1. **✅ 无限滚动感**：前后各60天，用户感觉可以无限滑动
2. **✅ 自动定位**：总是将选中日期居中显示
3. **✅ 流畅体验**：带动画的滚动效果
4. **✅ 易于扩展**：参数化设计，轻松调整范围
5. **✅ 性能优化**：控制数据量，避免过度渲染

## 未来改进

- [ ] 无限滚动：动态加载更多日期
- [ ] 手势优化：支持快速滑动到月初/月末
- [ ] 月份分隔：显示月份标签
- [ ] 节假日标记：高亮节假日

