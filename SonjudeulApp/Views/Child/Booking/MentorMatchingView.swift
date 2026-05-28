import SwiftUI

struct MentorMatchingView: View {
    @ObservedObject var bookingVM: BookingViewModel
    @State private var appeared = false

    let mentor = MockData.mentor

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Title
                VStack(spacing: 8) {
                    Text("김민지 멘토가\n매칭되었어요! 😊")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.sonjuText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                // Profile photo
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.sonjuPrimary.opacity(0.2), Color.sonjuPrimary.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 140, height: 140)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.sonjuPrimary)
                        .offset(y: 8)

                    // Waving hand badge
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            Text("👋")
                                .font(.system(size: 20))
                        )
                        .offset(x: 52, y: 52)
                }
                .frame(width: 140, height: 140)
                .scaleEffect(appeared ? 1 : 0.8)

                // Info rows
                VStack(spacing: 0) {
                    MentorInfoRow(icon: "building.columns.fill",
                                  iconColor: Color(hex: "#5C6BC0"),
                                  text: "이화여대 컴퓨터공학과 3학년")

                    Divider().padding(.horizontal, 20)

                    MentorInfoRow(icon: "checkmark.seal.fill",
                                  iconColor: .sonjuSuccess,
                                  text: "시니어 케어 교육 이수")

                    Divider().padding(.horizontal, 20)

                    MentorInfoRow(icon: "star.fill",
                                  iconColor: Color(hex: "#FFB300"),
                                  text: "평점 \(String(format: "%.1f", mentor.rating)) (리뷰 \(mentor.reviewCount)개)")
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 3)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                AmberButton(title: "멘토 프로필 보기") {
                    withAnimation { bookingVM.nextStep() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct MentorInfoRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
            }
            Text(text)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
