import SwiftUI

/// 忘记密码界面
struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 图标和说明
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("735BF2"))
                    
                    Text("重置密码")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("222B45"))
                    
                    Text("输入您的邮箱地址，我们将发送密码重置链接")
                        .font(.system(size: 14))
                        .foregroundColor(Color("8F9BB3"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 60)
                
                // 错误提示
                if viewModel.showError, let error = viewModel.errorMessage {
                    AuthErrorView(message: error) {
                        viewModel.clearError()
                    }
                    .padding(.horizontal, 24)
                }
                
                // 邮箱输入
                EmailTextField(
                    email: $viewModel.email,
                    error: viewModel.emailError
                )
                .padding(.horizontal, 24)
                
                // 发送按钮
                AuthButton(
                    title: viewModel.isLoading ? "发送中..." : "发送重置链接",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.isFormValid
                ) {
                    Task {
                        await viewModel.sendPasswordReset()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer()
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
            .alert("邮件已发送", isPresented: $viewModel.showSuccessAlert) {
                Button("好的") {
                    dismiss()
                }
            } message: {
                Text("密码重置链接已发送至 \(viewModel.email)，请查收邮件并按照说明重置密码。")
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}

