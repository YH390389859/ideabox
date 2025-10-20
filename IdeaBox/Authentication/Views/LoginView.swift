import SwiftUI

/// 登录界面
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Binding var showSignUp: Bool
    @Binding var showForgotPassword: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo 和标题
                VStack(spacing: 16) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("735BF2"))
                    
                    Text("欢迎回来")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("222B45"))
                    
                    Text("登录您的账号")
                        .font(.system(size: 16))
                        .foregroundColor(Color("8F9BB3"))
                }
                .padding(.top, 40)
                
                // 错误提示
                if viewModel.showError, let error = viewModel.errorMessage {
                    AuthErrorView(message: error) {
                        viewModel.clearError()
                    }
                }
                
                // 表单
                VStack(spacing: 16) {
                    EmailTextField(
                        email: $viewModel.email,
                        error: viewModel.emailError
                    )
                    
                    PasswordTextField(
                        password: $viewModel.password
                    )
                    
                    // 记住我 + 忘记密码
                    HStack {
                        Toggle("记住我", isOn: $viewModel.rememberMe)
                            .font(.system(size: 14))
                            .foregroundColor(Color("222B45"))
                        
                        Spacer()
                        
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("忘记密码?")
                                .font(.system(size: 14))
                                .foregroundColor(Color("735BF2"))
                        }
                    }
                }
                .padding(.top, 8)
                
                // 登录按钮
                AuthButton(
                    title: viewModel.isLoading ? "登录中..." : "登录",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.isFormValid
                ) {
                    Task {
                        await viewModel.signIn()
                    }
                }
                .padding(.top, 8)
                
                // 注册链接
                HStack(spacing: 4) {
                    Text("还没有账号?")
                        .font(.system(size: 14))
                        .foregroundColor(Color("8F9BB3"))
                    
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("立即注册")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("735BF2"))
                    }
                }
                .padding(.top, 16)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    LoginView(
        showSignUp: .constant(false),
        showForgotPassword: .constant(false)
    )
}

