import Foundation
import SwiftUI

/// 事件颜色类型
enum EventColorType {
    case purple
    case blue
    case green
    
    var color: Color {
        switch self {
        case .purple:
            return Color(hex: "735BF2")
        case .blue:
            return Color(hex: "0095FF")
        case .green:
            return Color(hex: "00B383")
        }
    }
}

/// 事件项
struct EventItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let startTime: String
    let endTime: String
    let colorType: EventColorType
    let date: Date
    
    /// 完整时间范围显示
    var timeRange: String {
        return "\(startTime)-\(endTime)"
    }
    
    /// 是否有详细描述
    var hasDescription: Bool {
        return description != nil && !description!.isEmpty
    }
}

