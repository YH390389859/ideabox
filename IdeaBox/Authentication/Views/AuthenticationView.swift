import SwiftUI

/// 认证主界面 (登录/注册入口)
struct AuthenticationView: View {
    @State private var showSignUp: Bool = false
    @State private var showForgotPassword: Bool = false
    
    var body: some View {
        LoginView(
            showSignUp: $showSignUp,
            showForgotPassword: $showForgotPassword
        )
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}

#Preview {
    AuthenticationView()
}

