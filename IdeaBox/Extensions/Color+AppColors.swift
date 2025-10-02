import SwiftUI

extension Color {
    /// 导航栏主题色（从 Assets 读取，自动适配浅色/深色模式）
    static var navigationAccent: Color {
        Color("NavigationAccent")
    }
    
    /// 根据颜色方案返回不同颜色
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

