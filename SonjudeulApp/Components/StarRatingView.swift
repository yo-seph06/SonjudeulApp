import SwiftUI

struct StarRatingView: View {
    let rating: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: starName(for: index))
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundColor(Color(hex: "#FFD700"))
            }
            Text(String(format: "%.1f", rating))
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
        }
    }

    private func starName(for index: Int) -> String {
        let filled = Double(index) <= rating
        return filled ? "star.fill" : "star"
    }
}
