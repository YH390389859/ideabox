import UIKit

// MARK: - Protocol

protocol HapticFeedbackProtocol {
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
    func prepare()
    func triggerNotification(_ type: UINotificationFeedbackGenerator.FeedbackType)
    func triggerSelection()
}

// MARK: - Haptic Manager

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

// MARK: - Navigation Haptic Event

enum NavigationHapticEvent {
    case buttonTap
    case todayButton
    case addButton
    case profileButton
    case invalidAction
    case actionSuccess
    
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

