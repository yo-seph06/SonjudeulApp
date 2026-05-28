import SwiftUI

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "더보기"

    var body: some View {
        HStack {
            Text(title)
                .font(.sonjuHeadline)
                .foregroundColor(.sonjuText)
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuPrimary)
                }
            }
        }
    }
}
