import Foundation
import FirebaseAuth

/// 用户实体模型
struct User: Identifiable, Codable, Equatable {
    // MARK: - Identity
    
    /// Firebase UID（唯一标识符）
    let id: String
    
    /// 用户邮箱
    let email: String
    
    // MARK: - Profile
    
    /// 显示名称（可选）
    var displayName: String?
    
    /// 头像 URL（可选）
    var photoURL: URL?
    
    // MARK: - Metadata
    
    /// 账号创建时间
    let createdAt: Date
    
    /// 最后登录时间
    var lastLoginAt: Date
    
    /// 邮箱验证状态
    var emailVerified: Bool
    
    // MARK: - Authentication
    
    /// 登录方式
    let authMethod: AuthenticationMethod
    
    // MARK: - Preferences (Local/Firestore)
    
    /// 记住登录状态
    var rememberMe: Bool
    
    /// 主题偏好
    var theme: AppTheme
    
    /// 语言偏好
    var language: String
    
    // MARK: - Computed Properties
    
    /// 邮箱是否已验证
    var isEmailVerified: Bool {
        return emailVerified
    }
    
    /// 用户首字母（用于头像占位符）
    var initials: String {
        guard let name = displayName, !name.isEmpty else {
            return email.prefix(1).uppercased()
        }
        return name.prefix(1).uppercased()
    }
    
    // MARK: - Initialization
    
    /// 从 Firebase User 创建
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL
        self.createdAt = firebaseUser.metadata.creationDate ?? Date()
        self.lastLoginAt = firebaseUser.metadata.lastSignInDate ?? Date()
        self.emailVerified = firebaseUser.isEmailVerified
        self.authMethod = .email  // Phase 1: 仅邮箱登录
        
        // 从 Firestore 加载偏好设置（默认值）
        self.rememberMe = false
        self.theme = .system
        self.language = Locale.current.language.languageCode?.identifier ?? "zh"
    }
    
    /// 完整初始化器（用于测试或自定义创建）
    init(
        id: String,
        email: String,
        displayName: String? = nil,
        photoURL: URL? = nil,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        emailVerified: Bool = false,
        authMethod: AuthenticationMethod = .email,
        rememberMe: Bool = false,
        theme: AppTheme = .system,
        language: String = "zh"
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.emailVerified = emailVerified
        self.authMethod = authMethod
        self.rememberMe = rememberMe
        self.theme = theme
        self.language = language
    }
}

// MARK: - Codable Keys

extension User {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case photoURL
        case createdAt
        case lastLoginAt
        case emailVerified
        case authMethod
        case rememberMe
        case theme
        case language
    }
}

