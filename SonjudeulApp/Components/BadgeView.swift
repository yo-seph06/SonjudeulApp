import SwiftUI

struct BadgeView: View {
    let text: String
    var color: Color = .sonjuPrimary

    var body: some View {
        Text(text)
            .font(.sonjuCaption)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(20)
    }
}
