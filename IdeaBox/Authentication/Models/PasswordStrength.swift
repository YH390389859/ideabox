import Foundation
import SwiftUI

/// 密码强度等级
enum PasswordStrength: Int, Equatable, Comparable {
    /// 非常弱（0-25分）
    case veryWeak = 0
    
    /// 弱（26-50分）
    case weak = 1
    
    /// 中等（51-75分）
    case medium = 2
    
    /// 强（76-90分）
    case strong = 3
    
    /// 非常强（91-100分）
    case veryStrong = 4
    
    // MARK: - Comparable
    
    static func < (lhs: PasswordStrength, rhs: PasswordStrength) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    // MARK: - Display Properties
    
    /// 强度标签
    var label: String {
        switch self {
        case .veryWeak:
            return "非常弱"
        case .weak:
            return "弱"
        case .medium:
            return "中等"
        case .strong:
            return "强"
        case .veryStrong:
            return "非常强"
        }
    }
    
    /// 强度颜色
    var color: Color {
        switch self {
        case .veryWeak:
            return Color.red
        case .weak:
            return Color.orange
        case .medium:
            return Color.yellow
        case .strong:
            return Color.green
        case .veryStrong:
            return Color.blue
        }
    }
    
    /// 强度图标（SF Symbols）
    var iconName: String {
        switch self {
        case .veryWeak:
            return "shield.slash.fill"
        case .weak:
            return "shield.lefthalf.filled"
        case .medium:
            return "shield.fill"
        case .strong:
            return "shield.checkered"
        case .veryStrong:
            return "checkmark.shield.fill"
        }
    }
    
    /// 强度百分比（用于进度条）
    var percentage: Double {
        switch self {
        case .veryWeak:
            return 0.2
        case .weak:
            return 0.4
        case .medium:
            return 0.6
        case .strong:
            return 0.8
        case .veryStrong:
            return 1.0
        }
    }
    
    /// 是否满足最低强度要求
    var meetsMinimumRequirement: Bool {
        return self >= .medium
    }
    
    /// 建议文本
    var suggestion: String? {
        switch self {
        case .veryWeak:
            return "密码太弱，建议使用大小写字母、数字和特殊字符的组合"
        case .weak:
            return "密码较弱，建议增加长度或使用更多字符类型"
        case .medium:
            return "密码强度一般，建议增加长度或特殊字符"
        case .strong:
            return nil
        case .veryStrong:
            return nil
        }
    }
    
    // MARK: - Calculation
    
    /// 从分数计算强度等级
    static func calculate(from score: Int) -> PasswordStrength {
        switch score {
        case 0...25:
            return .veryWeak
        case 26...50:
            return .weak
        case 51...75:
            return .medium
        case 76...90:
            return .strong
        default:
            return .veryStrong
        }
    }
    
    /// 从密码字符串计算强度
    /// - Parameter password: 密码字符串
    /// - Returns: 密码强度等级
    static func evaluate(_ password: String) -> PasswordStrength {
        var score = 0
        
        // 长度评分（最多30分）
        let length = password.count
        if length >= 8 {
            score += min(length * 2, 30)
        }
        
        // 包含小写字母（+10分）
        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            score += 10
        }
        
        // 包含大写字母（+10分）
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            score += 10
        }
        
        // 包含数字（+10分）
        if password.range(of: "[0-9]", options: .regularExpression) != nil {
            score += 10
        }
        
        // 包含特殊字符（+20分）
        if password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil {
            score += 20
        }
        
        // 字符多样性（+10分）
        let uniqueChars = Set(password)
        if uniqueChars.count >= length / 2 {
            score += 10
        }
        
        // 连续字符惩罚（-10分）
        if hasSequentialCharacters(password) {
            score -= 10
        }
        
        // 重复字符惩罚（-10分）
        if hasRepeatedCharacters(password) {
            score -= 10
        }
        
        // 确保分数在 0-100 范围内
        score = max(0, min(score, 100))
        
        return calculate(from: score)
    }
    
    // MARK: - Private Helpers
    
    /// 检测连续字符（如 abc、123）
    private static func hasSequentialCharacters(_ password: String) -> Bool {
        let chars = Array(password.lowercased())
        
        // 如果密码长度小于 3，无法检测连续字符
        guard chars.count >= 3 else {
            return false
        }
        
        for i in 0..<(chars.count - 2) {
            let char1 = chars[i].asciiValue ?? 0
            let char2 = chars[i + 1].asciiValue ?? 0
            let char3 = chars[i + 2].asciiValue ?? 0
            
            if char2 == char1 + 1 && char3 == char2 + 1 {
                return true
            }
        }
        return false
    }
    
    /// 检测重复字符（如 aaa、111）
    private static func hasRepeatedCharacters(_ password: String) -> Bool {
        let chars = Array(password)
        
        // 如果密码长度小于 3，无法检测重复字符
        guard chars.count >= 3 else {
            return false
        }
        
        for i in 0..<(chars.count - 2) {
            if chars[i] == chars[i + 1] && chars[i + 1] == chars[i + 2] {
                return true
            }
        }
        return false
    }
}

