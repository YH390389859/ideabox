import Foundation
import KeychainAccess
import FirebaseAuth

/// 用户会话管理服务实现
final class UserSessionManager: UserSessionManagerProtocol {
    
    private let keychain: Keychain
    private let sessionKey = "user_session"
    
    init() {
        self.keychain = Keychain(service: "com.ideabox.app.session")
            .synchronizable(true)  // iCloud 同步
            .accessibility(.afterFirstUnlock)  // 安全性设置
    }
    
    // MARK: - Session Creation
    
    func createSession(
        for user: User,
        accessToken: String,
        refreshToken: String?,
        rememberMe: Bool
    ) throws -> UserSession {
        return UserSession(
            userId: user.id,
            accessToken: accessToken,
            refreshToken: refreshToken,
            rememberMe: rememberMe
        )
    }
    
    // MARK: - Session Persistence
    
    func saveSession(_ session: UserSession) throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(session)
            let jsonString = String(data: data, encoding: .utf8)
            
            try keychain.set(jsonString ?? "", key: sessionKey)
        } catch {
            throw AuthError.keychainError
        }
    }
    
    func restoreSession() throws -> UserSession? {
        do {
            guard let jsonString = try keychain.get(sessionKey),
                  let data = jsonString.data(using: .utf8) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let session = try decoder.decode(UserSession.self, from: data)
            
            return session
        } catch {
            // 如果解析失败，返回 nil（会话不存在或损坏）
            if (error as NSError).domain == "KeychainAccess" {
                return nil
            }
            throw AuthError.keychainError
        }
    }
    
    func clearSession() throws {
        do {
            try keychain.remove(sessionKey)
        } catch {
            throw AuthError.keychainError
        }
    }
    
    // MARK: - Session Validation
    
    func isSessionValid(_ session: UserSession) -> Bool {
        return !session.isExpired
    }
    
    func isSessionExpiringSoon(_ session: UserSession) -> Bool {
        return session.isExpiringSoon
    }
    
    // MARK: - Session Refresh
    
    func refreshSession(_ session: UserSession) async throws -> UserSession {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.sessionExpired
        }
        
        do {
            // 强制刷新 Firebase ID Token
            let newToken = try await currentUser.getIDTokenForcingRefresh(true)
            
            // 更新会话
            var refreshedSession = session
            refreshedSession.updateAccessToken(newToken)
            refreshedSession.extend()
            
            return refreshedSession
        } catch {
            throw AuthError.tokenRefreshFailed
        }
    }
    
    // MARK: - Session Activity
    
    func touchSession(_ session: UserSession) -> UserSession {
        var updatedSession = session
        updatedSession.touch()
        return updatedSession
    }
}

