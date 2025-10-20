import SwiftUI

/// 注册界面
struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    VStack(spacing: 8) {
                        Text("创建账号")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("222B45"))
                        
                        Text("开始使用 IdeaBox")
                            .font(.system(size: 16))
                            .foregroundColor(Color("8F9BB3"))
                    }
                    .padding(.top, 20)
                    
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
                            password: $viewModel.password,
                            error: viewModel.passwordError,
                            showStrengthIndicator: true,
                            strength: viewModel.passwordStrength
                        )
                        
                        PasswordTextField(
                            password: $viewModel.confirmPassword,
                            placeholder: "确认密码",
                            error: viewModel.confirmPasswordError
                        )
                        
                        // 服务条款
                        HStack(alignment: .top, spacing: 8) {
                            Toggle("", isOn: $viewModel.agreedToTerms)
                                .labelsHidden()
                            
                            HStack(spacing: 0) {
                                Text("我已阅读并同意")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("8F9BB3"))
                                Text("服务条款")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color("735BF2"))
                                Text("和")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("8F9BB3"))
                                Text("隐私政策")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color("735BF2"))
                            }
                        }
                    }
                    
                    // 注册按钮
                    AuthButton(
                        title: viewModel.isLoading ? "注册中..." : "注册",
                        isLoading: viewModel.isLoading,
                        isEnabled: viewModel.isFormValid
                    ) {
                        Task {
                            await viewModel.signUp()
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color("222B45"))
                    }
                }
            }
            .alert("验证邮件已发送", isPresented: $viewModel.showEmailVerificationAlert) {
                Button("好的") {
                    dismiss()
                }
            } message: {
                Text("我们已向 \(viewModel.email) 发送了验证邮件，请查收并点击验证链接。")
            }
        }
    }
}

#Preview {
    SignUpView()
}

