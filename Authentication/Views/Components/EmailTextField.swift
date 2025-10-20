import SwiftUI

/// 邮箱输入框组件
struct EmailTextField: View {
    @Binding var email: String
    var error: String?
    var placeholder: String = "邮箱地址"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(Color("8F9BB3"))
                    .frame(width: 20)
                
                TextField(placeholder, text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .font(.system(size: 16))
                    .foregroundColor(Color("222B45"))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(error != nil ? Color.red : Color("E4E9F2"), lineWidth: 1)
            )
            
            if let error = error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EmailTextField(email: .constant(""))
        EmailTextField(
            email: .constant("invalid"),
            error: "邮箱格式不正确"
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

