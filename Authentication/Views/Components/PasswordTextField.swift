import SwiftUI

/// 密码输入框组件
struct PasswordTextField: View {
    @Binding var password: String
    var placeholder: String = "密码"
    var error: String?
    var showStrengthIndicator: Bool = false
    var strength: PasswordStrength = .veryWeak
    
    @State private var isSecured: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(Color("8F9BB3"))
                    .frame(width: 20)
                
                if isSecured {
                    SecureField(placeholder, text: $password)
                        .textContentType(.password)
                        .font(.system(size: 16))
                        .foregroundColor(Color("222B45"))
                } else {
                    TextField(placeholder, text: $password)
                        .autocapitalization(.none)
                        .font(.system(size: 16))
                        .foregroundColor(Color("222B45"))
                }
                
                Button(action: {
                    isSecured.toggle()
                }) {
                    Image(systemName: isSecured ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(Color("8F9BB3"))
                        .frame(width: 20)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(error != nil ? Color.red : Color("E4E9F2"), lineWidth: 1)
            )
            
            if showStrengthIndicator && !password.isEmpty {
                strengthIndicator
            }
            
            if let error = error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
    
    private var strengthIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(index < strength.rawValue + 1 ? strength.color : Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            
            Text(strength.label)
                .font(.system(size: 12))
                .foregroundColor(strength.color)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        PasswordTextField(password: .constant(""))
        
        PasswordTextField(
            password: .constant("Test123"),
            placeholder: "输入密码",
            showStrengthIndicator: true,
            strength: .medium
        )
        
        PasswordTextField(
            password: .constant("weak"),
            error: "密码强度不足"
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

