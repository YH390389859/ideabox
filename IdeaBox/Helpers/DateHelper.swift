import Foundation

class DateHelper {
    static let shared = DateHelper()
    private let calendar = Calendar.current
    
    private init() {}
    
    // 获取当前周的日期列表（从今天开始的7天）- 用于兼容
    func getWeekDays(from date: Date = Date()) -> [DayItem] {
        return getExtendedDays(centerDate: date, daysBefore: 3, daysAfter: 3)
    }
    
    // 获取扩展的日期列表（可横向滚动）
    // centerDate: 中心日期
    // daysBefore: 中心日期之前的天数
    // daysAfter: 中心日期之后的天数
    func getExtendedDays(centerDate: Date = Date(), daysBefore: Int = 60, daysAfter: Int = 60) -> [DayItem] {
        var days: [DayItem] = []
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -daysBefore, to: centerDate) ?? centerDate
        
        // 生成前后共 daysBefore + 1 + daysAfter 天的数据
        for i in 0...(daysBefore + daysAfter) {
            if let targetDate = calendar.date(byAdding: .day, value: i, to: startDate) {
                let day = calendar.component(.day, from: targetDate)
                let weekday = getWeekdayString(from: targetDate)
                let isToday = calendar.isDate(targetDate, inSameDayAs: today)
                
                // 计算 weekdayIndex (1-7, 1=周一)
                let systemWeekday = calendar.component(.weekday, from: targetDate)
                let weekdayIndex = (systemWeekday + 5) % 7 + 1
                
                days.append(DayItem(
                    weekday: weekday,
                    day: day,
                    date: targetDate,
                    isToday: isToday,
                    weekdayIndex: weekdayIndex
                ))
            }
        }
        
        return days
    }
    
    // 获取星期几的中文字符
    private func getWeekdayString(from date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        return weekdays[weekday - 1]
    }
    
    // 格式化日期显示（如：10月1日 - 周三）
    func formatDateHeader(_ date: Date) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = getWeekdayString(from: date)
        
        return "\(month)月\(day)日 - 周\(weekday)"
    }
    
    // 获取农历日期（简化版本，实际项目中需要农历转换库）
    func getLunarDate(_ date: Date) -> String {
        // 这里是简化版本，实际应用中需要使用农历转换库
        // 目前返回示例数据
        let day = calendar.component(.day, from: date)
        
        // 农历月份对照
        let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月",
                          "七月", "八月", "九月", "十月", "冬月", "腊月"]
        let lunarDays = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
        
        // 简化计算（仅作示例）
        let month = calendar.component(.month, from: date)
        let lunarMonth = lunarMonths[(month + 6) % 12]
        let lunarDay = lunarDays[min(day - 1, 29)]
        
        return "\(lunarMonth)\(lunarDay)"
    }
    
    // 判断是否是今天
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    // MARK: - 周数据计算方法（新增）
    
    /// 获取指定日期所在周的周一
    /// - Parameter date: 目标日期
    /// - Returns: 该日期所在周的周一
    func getMonday(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        // weekday: 1=周日, 2=周一, ..., 7=周六
        // 计算距离周一的天数
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: date)!
    }
    
    /// 生成周数据
    /// - Parameters:
    ///   - offset: 周偏移量（相对于 baseDate 所在周，0=当前周, -1=上周, +1=下周）
    ///   - baseDate: 基准日期（默认为今天）
    /// - Returns: WeekData 对象，包含完整7天数据
    func getWeek(offset: Int, relativeTo baseDate: Date = Date()) -> WeekData {
        let baseMonday = getMonday(for: baseDate)
        let targetMonday = calendar.date(byAdding: .weekOfYear, 
                                          value: offset, 
                                          to: baseMonday)!
        
        var days: [DayItem] = []
        let today = calendar.startOfDay(for: Date())
        
        // 生成周一到周日共7天
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, 
                                      value: dayOffset, 
                                      to: targetMonday)!
            let day = calendar.component(.day, from: date)
            let weekday = getWeekdayString(from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let weekdayIndex = dayOffset + 1  // 1-7 (1=周一)
            
            days.append(DayItem(
                weekday: weekday,
                day: day,
                date: date,
                isToday: isToday,
                weekdayIndex: weekdayIndex
            ))
        }
        
        let sunday = calendar.date(byAdding: .day, value: 6, to: targetMonday)!
        
        return WeekData(
            id: UUID(),
            offset: offset,
            monday: targetMonday,
            sunday: sunday,
            days: days
        )
    }
    
    /// 计算两个日期之间的周偏移量
    /// - Parameters:
    ///   - date: 目标日期
    ///   - baseDate: 基准日期
    /// - Returns: 周偏移量（整数）
    func weekOffset(for date: Date, relativeTo baseDate: Date) -> Int {
        let monday1 = getMonday(for: baseDate)
        let monday2 = getMonday(for: date)
        let components = calendar.dateComponents([.weekOfYear], 
                                                   from: monday1, 
                                                   to: monday2)
        return components.weekOfYear ?? 0
    }
    
    /// 根据星期几在指定周获取日期
    /// - Parameters:
    ///   - weekData: 周数据
    ///   - weekday: 星期几 (1-7, 1=周一)
    /// - Returns: 对应日期，无效输入返回 nil
    func dateInWeek(_ weekData: WeekData, weekday: Int) -> Date? {
        return weekData.date(for: weekday)
    }
}

