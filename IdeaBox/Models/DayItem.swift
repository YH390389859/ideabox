import Foundation

struct DayItem: Identifiable, Equatable {
    let id = UUID()
    let weekday: String
    let day: Int
    let date: Date
    let isToday: Bool
    
    /// 周内索引（1-7，1=周一，7=周日）
    let weekdayIndex: Int
    
    static func == (lhs: DayItem, rhs: DayItem) -> Bool {
        Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)
    }
}

