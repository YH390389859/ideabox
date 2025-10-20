import Foundation
import FirebaseAuth

/// 认证服务实现
final class AuthenticationService: AuthenticationServiceProtocol {
    
    // MARK: - User Registration
    
    func signUp(email: String, password: String) async throws -> User {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            return User(from: authResult.user)
        } catch {
            throw AuthError(from: error)
        }
    }
    
    func sendEmailVerification(to user: User) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.sessionExpired
        }
        
        do {
            try await currentUser.sendEmailVerification()
        } catch {
            throw AuthError(from: error)
        }
    }
    
    // MARK: - User Login
    
    func signIn(email: String, password: String, rememberMe: Bool) async throws -> User {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            var user = User(from: authResult.user)
            user.rememberMe = rememberMe
            return user
        } catch {
            throw AuthError(from: error)
        }
    }
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        return User(from: firebaseUser)
    }
    
    func isUserSignedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    // MARK: - User Logout
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError(from: error)
        }
    }
    
    // MARK: - Password Reset
    
    func sendPasswordReset(to email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError(from: error)
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.sessionExpired
        }
        
        guard let email = currentUser.email else {
            throw AuthError.invalidToken
        }
        
        // 重新认证用户
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        do {
            try await currentUser.reauthenticate(with: credential)
            try await currentUser.updatePassword(to: newPassword)
        } catch {
            throw AuthError(from: error)
        }
    }
    
    // MARK: - Account Management
    
    func deleteAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.sessionExpired
        }
        
        do {
            try await currentUser.delete()
        } catch {
            throw AuthError(from: error)
        }
    }
}

