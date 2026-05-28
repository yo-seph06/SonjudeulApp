import SwiftUI

struct AmberButton: View {
    let title: String
    var isSecondary: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.sonjuHeadline)
                .foregroundColor(
                    disabled ? .sonjuSecondary :
                    (isSecondary ? .sonjuPrimary : .white)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    disabled ? Color.sonjuDivider :
                    (isSecondary ? Color.sonjuPrimary.opacity(0.12) : Color.sonjuPrimary)
                )
                .cornerRadius(14)
        }
        .buttonStyle(PressButtonStyle())
        .disabled(disabled)
    }
}
