import SwiftUI

/// 认证错误提示组件
struct AuthErrorView: View {
    var message: String
    var onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color("222B45"))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(Color("8F9BB3"))
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        AuthErrorView(
            message: "邮箱格式不正确",
            onDismiss: {}
        )
        
        AuthErrorView(
            message: "登录失败，请检查您的邮箱和密码",
            onDismiss: {}
        )
    }
    .padding()
}

