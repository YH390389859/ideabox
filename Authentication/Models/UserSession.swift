import Foundation
import UIKit

/// 用户会话模型
struct UserSession: Codable, Equatable {
    // MARK: - Session Identity
    
    /// 会话 ID（UUID）
    let id: String
    
    /// 用户 ID（Firebase UID）
    let userId: String
    
    /// 访问令牌（存储在 Keychain）
    var accessToken: String
    
    /// 刷新令牌（存储在 Keychain）
    var refreshToken: String?
    
    // MARK: - Session Timing
    
    /// 会话创建时间
    let createdAt: Date
    
    /// 会话过期时间
    var expiresAt: Date
    
    /// 最后访问时间（用于活跃度跟踪）
    var lastAccessedAt: Date
    
    // MARK: - Session Settings
    
    /// 是否"记住我"（90天会话）
    let rememberMe: Bool
    
    /// 设备标识（用于多设备管理）
    let deviceId: String
    
    /// 设备名称（如"iPhone 15 Pro"）
    var deviceName: String?
    
    // MARK: - Computed Properties
    
    /// 会话是否已过期
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    /// 会话是否即将过期（剩余不到1天）
    var isExpiringSoon: Bool {
        let oneDayFromNow = Date().addingTimeInterval(24 * 60 * 60)
        return expiresAt < oneDayFromNow && !isExpired
    }
    
    /// 会话是否仍然有效
    var isValid: Bool {
        return !isExpired
    }
    
    /// 会话剩余时间（秒）
    var remainingTime: TimeInterval {
        return expiresAt.timeIntervalSince(Date())
    }
    
    /// 会话剩余天数
    var remainingDays: Int {
        let days = remainingTime / (24 * 60 * 60)
        return max(0, Int(ceil(days)))
    }
    
    // MARK: - Initialization
    
    /// 创建新会话
    init(
        userId: String,
        accessToken: String,
        refreshToken: String? = nil,
        rememberMe: Bool = false,
        deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
        deviceName: String? = UIDevice.current.name
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.createdAt = Date()
        self.rememberMe = rememberMe
        self.deviceId = deviceId
        self.deviceName = deviceName
        
        // 设置过期时间：记住我 = 90天，否则 = 30天
        let sessionDuration = rememberMe ? (90 * 24 * 60 * 60.0) : (30 * 24 * 60 * 60.0)
        self.expiresAt = Date().addingTimeInterval(sessionDuration)
        self.lastAccessedAt = Date()
    }
    
    /// 完整初始化器（用于反序列化或测试）
    init(
        id: String,
        userId: String,
        accessToken: String,
        refreshToken: String?,
        createdAt: Date,
        expiresAt: Date,
        lastAccessedAt: Date,
        rememberMe: Bool,
        deviceId: String,
        deviceName: String?
    ) {
        self.id = id
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.lastAccessedAt = lastAccessedAt
        self.rememberMe = rememberMe
        self.deviceId = deviceId
        self.deviceName = deviceName
    }
    
    // MARK: - Methods
    
    /// 刷新会话访问时间
    mutating func touch() {
        self.lastAccessedAt = Date()
    }
    
    /// 更新访问令牌
    mutating func updateAccessToken(_ token: String) {
        self.accessToken = token
        self.lastAccessedAt = Date()
    }
    
    /// 延长会话（刷新过期时间）
    mutating func extend(by interval: TimeInterval = 30 * 24 * 60 * 60) {
        self.expiresAt = Date().addingTimeInterval(interval)
        self.lastAccessedAt = Date()
    }
}

// MARK: - Codable Keys

extension UserSession {
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case accessToken
        case refreshToken
        case createdAt
        case expiresAt
        case lastAccessedAt
        case rememberMe
        case deviceId
        case deviceName
    }
}

