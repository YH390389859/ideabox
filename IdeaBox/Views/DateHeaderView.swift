import SwiftUI

struct DateHeaderView: View {
    let selectedDate: Date
    private let dateHelper = DateHelper.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dateHelper.formatDateHeader(selectedDate))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "FF453B"))
            
            Text(dateHelper.getLunarDate(selectedDate))
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "999999"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(height: 50)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: "EBEBEB"))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

#Preview {
    DateHeaderView(selectedDate: Date())
}

