import SwiftUI

struct MentorRatingView: View {
    let booking: BookingRecord
    @EnvironmentObject var bookingStore: BookingStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedRating: Int = 0
    @State private var comment: String = ""
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Mentor avatar
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.sonjuPrimary, Color.sonjuDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 84, height: 84)
                            Text(String(booking.mentorName.prefix(1)))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text(booking.mentorName)
                            .font(.sonjuTitle)
                            .foregroundColor(.sonjuText)
                        Text("멘토 선생님 방문은 어떠셨나요?")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                    }
                    .padding(.top, 24)

                    // Star rating
                    SonjuCard {
                        VStack(spacing: 16) {
                            Text("별점을 선택해주세요")
                                .font(.sonjuHeadline)
                                .foregroundColor(.sonjuText)

                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedRating = star
                                        }
                                    } label: {
                                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(star <= selectedRating ? Color(hex: "#FFB300") : Color.sonjuDivider)
                                            .scaleEffect(star <= selectedRating ? 1.1 : 1.0)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if selectedRating > 0 {
                                Text(ratingLabel)
                                    .font(.sonjuBody)
                                    .foregroundColor(.sonjuPrimary)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)

                    // Comment
                    SonjuCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("한 줄 후기 (선택)")
                                .font(.sonjuHeadline)
                                .foregroundColor(.sonjuText)
                            TextEditor(text: $comment)
                                .font(.sonjuBody)
                                .frame(minHeight: 90)
                                .padding(12)
                                .background(Color.sonjuBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.sonjuDivider, lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if comment.isEmpty {
                                            Text("멘토 선생님께 한마디 남겨주세요")
                                                .font(.sonjuBody)
                                                .foregroundColor(.sonjuSecondary.opacity(0.6))
                                                .padding(16)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        }
                                    }
                                )
                        }
                    }
                    .padding(.horizontal, 24)

                    AmberButton(title: "평가 완료") {
                        guard selectedRating > 0 else { return }
                        bookingStore.rateBooking(id: booking.id, rating: selectedRating, comment: comment)
                        withAnimation { showSuccess = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .opacity(selectedRating > 0 ? 1 : 0.5)
                }
            }

            if showSuccess {
                Color.black.opacity(0.4).ignoresSafeArea().transition(.opacity)
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundColor(Color(hex: "#FFB300"))
                    Text("평가해주셔서 감사해요!")
                        .font(.sonjuLargeTitle)
                        .foregroundColor(.sonjuText)
                    Text("\(selectedRating)점 별점이 등록되었어요")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuSecondary)
                }
                .padding(40)
                .background(Color.sonjuCard)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.15), radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("멘토 평가")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.4), value: showSuccess)
    }

    private var ratingLabel: String {
        switch selectedRating {
        case 1: return "아쉬웠어요"
        case 2: return "조금 아쉬웠어요"
        case 3: return "보통이에요"
        case 4: return "좋았어요"
        case 5: return "매우 만족해요! 👍"
        default: return ""
        }
    }
}
