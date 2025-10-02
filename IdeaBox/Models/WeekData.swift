import Foundation

/// 周数据模型
/// 表示完整的一周（周一到周日）
struct WeekData: Identifiable, Equatable {
    /// 唯一标识符
    let id: UUID
    
    /// 周偏移量（相对于今天所在周）
    /// 0 = 今天所在周, -1 = 上一周, +1 = 下一周
    let offset: Int
    
    /// 周一的日期
    let monday: Date
    
    /// 周日的日期
    let sunday: Date
    
    /// 7天的数据（周一到周日）
    let days: [DayItem]
    
    /// 是否包含今天
    var containsToday: Bool {
        days.contains { $0.isToday }
    }
    
    /// 获取指定星期几的日期
    /// - Parameter weekday: 1-7 (1=周一, 7=周日)
    /// - Returns: 对应日期，无效输入返回 nil
    func date(for weekday: Int) -> Date? {
        guard weekday >= 1 && weekday <= 7 else { return nil }
        return days[weekday - 1].date
    }
    
    /// Equatable 实现：两个周一相同的周被认为是相等的
    static func == (lhs: WeekData, rhs: WeekData) -> Bool {
        Calendar.current.isDate(lhs.monday, inSameDayAs: rhs.monday)
    }
}


