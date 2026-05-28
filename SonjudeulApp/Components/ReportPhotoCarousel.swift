import SwiftUI

struct ReportPhotoCarousel: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    PhotoPlaceholder()
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct PhotoPlaceholder: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.sonjuPrimary.opacity(0.3), Color.sonjuDeep.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white.opacity(0.7))
                Text("사진")
                    .font(.sonjuCaption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 160, height: 120)
        .cornerRadius(14)
    }
}
