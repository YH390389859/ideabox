import SwiftUI

/// 用于传递滚动偏移量的 PreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// 视图扩展：用于检测滚动位置
extension View {
    func onScrollOffsetChange(
        coordinateSpace: String = "scroll",
        onChange: @escaping (CGFloat) -> Void
    ) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named(coordinateSpace)).minY
                )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: onChange)
    }
}

