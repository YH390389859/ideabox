import SwiftUI

/// 认证按钮组件
struct AuthButton: View {
    var title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            guard !isLoading && isEnabled else { return }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isEnabled && !isLoading ?
                    Color("735BF2") :
                    Color("735BF2").opacity(0.5)
            )
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        AuthButton(title: "登录") {}
        AuthButton(title: "正在登录...", isLoading: true) {}
        AuthButton(title: "登录", isEnabled: false) {}
    }
    .padding()
}

