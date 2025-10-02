# Contract: HapticFeedback

**Feature**: 005-apple  
**Date**: 2025-10-02  
**Status**: Defined

## 职责

定义触觉反馈的触发规范和实现接口，确保用户交互提供及时、恰当的触觉响应。

---

## 接口定义

### Protocol

```swift
import UIKit

protocol HapticFeedbackProtocol {
    /// 触发触觉反馈
    /// - Parameter style: 反馈强度类型
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
    
    /// 准备触觉反馈生成器（优化响应速度）
    func prepare()
    
    /// 触发通知型触觉反馈
    /// - Parameter type: 通知类型（成功/警告/错误）
    func triggerNotification(_ type: UINotificationFeedbackGenerator.FeedbackType)
    
    /// 触发选择型触觉反馈（用于选择器等）
    func triggerSelection()
}
```

### 标准实现

```swift
import UIKit

/// 触觉反馈管理器（单例）
final class HapticManager: HapticFeedbackProtocol {
    static let shared = HapticManager()
    
    // MARK: - Generator Instances
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - State
    
    private var isEnabled: Bool = true
    private var lastTriggerTime: Date?
    private let minimumInterval: TimeInterval = 0.1 // 防止过于频繁触发
    
    private init() {
        // 预加载 generators
        prepare()
    }
    
    // MARK: - HapticFeedbackProtocol
    
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled, canTrigger() else { return }
        
        switch style {
        case .light:
            impactLight.impactOccurred()
            impactLight.prepare()
        case .medium:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        case .heavy:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()
        case .soft:
            impactLight.impactOccurred(intensity: 0.5)
            impactLight.prepare()
        case .rigid:
            impactMedium.impactOccurred(intensity: 1.0)
            impactMedium.prepare()
        @unknown default:
            impactLight.impactOccurred()
            impactLight.prepare()
        }
        
        lastTriggerTime = Date()
    }
    
    func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    func triggerNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled, canTrigger() else { return }
        notificationGenerator.notificationOccurred(type)
        notificationGenerator.prepare()
        lastTriggerTime = Date()
    }
    
    func triggerSelection() {
        guard isEnabled, canTrigger() else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
        lastTriggerTime = Date()
    }
    
    // MARK: - Helper Methods
    
    private func canTrigger() -> Bool {
        guard let lastTime = lastTriggerTime else { return true }
        return Date().timeIntervalSince(lastTime) >= minimumInterval
    }
    
    /// 启用/禁用触觉反馈
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}
```

---

## 导航栏触觉事件

### 事件定义

```swift
enum NavigationHapticEvent {
    /// 标准导航按钮点击
    case buttonTap
    
    /// "今天"按钮点击（主要操作）
    case todayButton
    
    /// 添加按钮点击（主要操作）
    case addButton
    
    /// 个人中心按钮点击
    case profileButton
    
    /// 无效操作（可选）
    case invalidAction
    
    /// 操作成功（可选）
    case actionSuccess
    
    /// 转换为触觉反馈样式
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .buttonTap, .profileButton:
            return .light
        case .todayButton, .addButton:
            return .medium
        case .invalidAction:
            return .rigid
        case .actionSuccess:
            return .soft
        }
    }
}
```

### SwiftUI 集成

```swift
import SwiftUI

extension View {
    /// 添加触觉反馈到视图交互
    func hapticFeedback(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        enabled: Bool = true
    ) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                if enabled {
                    HapticManager.shared.trigger(style)
                }
            }
        )
    }
    
    /// 添加导航事件触觉反馈
    func navigationHaptic(_ event: NavigationHapticEvent, enabled: Bool = true) -> some View {
        self.hapticFeedback(event.hapticStyle, enabled: enabled)
    }
}
```

---

## 使用规范

### 基础使用

```swift
Button("添加") {
    // 按钮操作
}
.navigationHaptic(.addButton)
```

### 条件触发

```swift
Button("Today") {
    scrollToToday()
}
.navigationHaptic(.todayButton, enabled: !Calendar.current.isDateInToday(selectedDate))
```

### 结合动画

```swift
Button("Profile") {
    withAnimation {
        // 触觉反馈应在动画开始时触发，而非结束后
        HapticManager.shared.trigger(.light)
        showProfile = true
    }
}
```

### 响应辅助功能

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

Button("Add") {
    // 减少动画模式下可能也想减少触觉（可选）
    if !reduceMotion {
        HapticManager.shared.trigger(.medium)
    }
    showAddSheet = true
}
```

---

## 触觉反馈规则

### 导航栏触觉映射

| 交互 | 触觉类型 | 强度 | 理由 |
|------|---------|------|------|
| "今天"按钮点击 | Impact | Medium | 重要导航操作，需要明显反馈 |
| "添加"按钮点击 | Impact | Medium | 主要操作入口，强调重要性 |
| "个人中心"点击 | Impact | Light | 标准导航，轻微反馈 |
| 快速重复点击 | 去抖动 | - | 防止触觉疲劳 |
| 无效操作 | Impact | Rigid | 轻微的"碰壁"感（可选） |
| 操作成功 | Notification | Success | 明确的完成感（可选） |

### 时机规则

1. **视觉反馈同步**: 触觉应在视觉反馈开始时触发，延迟 < 16ms
2. **防止重复**: 100ms 内的重复触发应被抑制
3. **后台处理**: App 在后台时自动禁用
4. **低电量模式**: 系统自动处理，无需额外代码

### 最佳实践

✅ **DO**:
- 在用户主动触发的交互上使用
- 使用恰当的强度（light/medium/heavy）
- 与视觉动画配合使用
- 提供禁用选项（可选）

❌ **DON'T**:
- 过度使用（每个交互都加）
- 在自动事件上使用（如数据加载）
- 强度过大（heavy 应谨慎使用）
- 在短时间内频繁触发

---

## 性能优化

### Generator 预加载

```swift
// 在视图出现时预加载
.onAppear {
    HapticManager.shared.prepare()
}

// 在按钮按下时预加载（而非释放时）
.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
    // 释放时触发
    HapticManager.shared.trigger(.light)
} onPressingChanged: { pressing in
    if pressing {
        // 按下时预加载，减少触发延迟
        HapticManager.shared.prepare()
    }
}
```

### 内存管理

```swift
// 单例模式避免重复创建 Generator
// Generator 实例较轻量，无需主动释放

// 长时间不使用时可以选择重置（可选）
extension HapticManager {
    func reset() {
        // 重新创建 generators（系统会回收旧的）
        prepare()
    }
}
```

---

## 测试规范

### 单元测试

```swift
class HapticManagerTests: XCTestCase {
    let hapticManager = HapticManager.shared
    
    func testTriggerDoesNotThrow() {
        // 触觉反馈不应抛出异常
        XCTAssertNoThrow(hapticManager.trigger(.light))
    }
    
    func testPrepareSucceeds() {
        XCTAssertNoThrow(hapticManager.prepare())
    }
    
    func testDebouncing() {
        hapticManager.trigger(.light)
        let firstTrigger = hapticManager.lastTriggerTime
        
        // 立即再次触发（应被去抖动）
        hapticManager.trigger(.light)
        let secondTrigger = hapticManager.lastTriggerTime
        
        // 验证触发时间没有更新（或间隔足够）
        XCTAssertNotNil(firstTrigger)
    }
}
```

### 真机测试

⚠️ **重要**: 触觉反馈必须在真机上测试，模拟器无法模拟触觉

**测试步骤**:
1. 在真机上运行应用
2. 点击每个导航按钮
3. 验证触觉反馈：
   - "今天"和"添加"：中等强度，明显但不刺激
   - "个人中心"：轻微强度，几乎察觉不到
4. 快速连续点击，验证去抖动
5. 在不同设备上测试（iPhone 各型号触觉引擎不同）

### 用户测试

```swift
// 提供测试界面（可选）
#if DEBUG
struct HapticTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("Light") {
                HapticManager.shared.trigger(.light)
            }
            Button("Medium") {
                HapticManager.shared.trigger(.medium)
            }
            Button("Heavy") {
                HapticManager.shared.trigger(.heavy)
            }
        }
    }
}
#endif
```

---

## 辅助功能考虑

### 减少动画模式

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// 可选：在减少动画模式下也减少触觉
Button("Action") {
    if !reduceMotion {
        HapticManager.shared.trigger(.medium)
    }
    performAction()
}
```

### 用户偏好设置（可选）

```swift
// 提供触觉反馈开关
@AppStorage("hapticsEnabled") private var hapticsEnabled = true

Button("Action") {
    if hapticsEnabled {
        HapticManager.shared.trigger(.medium)
    }
    performAction()
}
```

---

## 故障排查

### 常见问题

**问题 1**: 模拟器上触觉不工作
- **原因**: 模拟器不支持触觉反馈
- **解决**: 必须在真机上测试

**问题 2**: 触觉延迟明显
- **原因**: Generator 未预加载
- **解决**: 在视图出现或按钮按下时调用 `prepare()`

**问题 3**: 某些设备触觉很弱
- **原因**: 旧设备的 Taptic Engine 性能较弱
- **解决**: 使用更高强度（但注意新设备可能过强）

**问题 4**: 后台播放时触觉不工作
- **原因**: 系统限制
- **解决**: 正常行为，无需处理

---

## 契约保证

本契约确保：

✅ **及时性**: 触觉反馈延迟 < 50ms  
✅ **恰当性**: 根据交互重要性选择合适强度  
✅ **性能**: Generator 预加载，避免首次触发延迟  
✅ **防抖动**: 100ms 内重复触发被抑制  
✅ **可测试性**: 提供真机测试指南  
✅ **可配置性**: 支持启用/禁用设置

---

**完成时间**: 2025-10-02  
**审阅状态**: 已审阅  
**实施状态**: 待实施  
**测试要求**: 必须真机验证

