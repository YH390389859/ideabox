import Foundation

/// 导航栏的状态管理
struct NavigationState: Equatable {
    /// 当前选中的导航项 ID
    var selectedItemId: String?
    
    /// 是否正在执行动画
    var isAnimating: Bool = false
    
    /// 上一次选中的导航项 ID（用于转场动画）
    var previousItemId: String?
}

