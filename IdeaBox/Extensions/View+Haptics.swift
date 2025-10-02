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

