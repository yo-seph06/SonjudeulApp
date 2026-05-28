import SwiftUI

struct BookingHistoryView: View {
    @EnvironmentObject var bookingStore: BookingStore
    @State private var navigateToBooking = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if bookingStore.bookings.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 52))
                                    .foregroundColor(.sonjuPrimary.opacity(0.4))
                                    .padding(.top, 60)
                                Text("아직 예약 내역이 없어요")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuText)
                                Text("첫 예약을 완료하면\n방문 이력이 이곳에 쌓여요")
                                    .font(.sonjuBody)
                                    .foregroundColor(.sonjuSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            if let next = bookingStore.nextBooking {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("다음 방문")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.white.opacity(0.85))
                                        Text(next.date)
                                            .font(.sonjuHeadline)
                                            .foregroundColor(.white)
                                        Text(next.plan)
                                            .font(.sonjuCaption)
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                    Spacer()
                                    Image(systemName: "calendar.badge.clock")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(
                                        colors: [Color.sonjuPrimary, Color.sonjuDeep],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: Color.sonjuPrimary.opacity(0.4), radius: 10, x: 0, y: 4)
                            }

                            ForEach(bookingStore.bookings) { item in
                                BookingCard(item: item)
                            }
                        }

                        // New booking CTA
                        Button {
                            navigateToBooking = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.sonjuPrimary)
                                Text("새 예약 추가하기")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.sonjuPrimary.opacity(0.1))
                            .cornerRadius(14)
                        }
                        .buttonStyle(PressButtonStyle())
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("예약내역")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $navigateToBooking) {
                BookingFlowView()
            }
        }
    }
}

#Preview {
    BookingHistoryView()
        .environmentObject(BookingStore())
}

struct BookingCard: View {
    let item: BookingRecord
    @State private var showProfile = false

    private var icon: String {
        switch item.status {
        case "예약 확정":   return "calendar.badge.checkmark"
        case "멘토 찾는 중": return "magnifyingglass.circle.fill"
        case "방문 완료":   return "checkmark.circle.fill"
        default:           return "calendar"
        }
    }

    var body: some View {
        SonjuCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(item.statusColor.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .foregroundColor(item.statusColor)
                            .font(.system(size: 20))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.date)
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                        Text(item.plan)
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuText)
                    }
                    Spacer()
                    Text(item.status)
                        .font(.sonjuCaption)
                        .foregroundColor(item.statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(item.statusColor.opacity(0.1))
                        .cornerRadius(20)
                }

                if item.status == "예약 확정", item.mentorId != nil {
                    Divider()
                        .background(Color.sonjuDivider)
                        .padding(.top, 12)

                    NavigationLink(destination: MentorProfileView(mentorName: item.mentorName, mentorId: item.mentorId)) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.sonjuPrimary)
                            Text("멘토 프로필 보기")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(.sonjuSecondary)
                        }
                        .padding(.top, 10)
                    }
                    .buttonStyle(.plain)
                }

                if item.status == "방문 완료" {
                    Divider()
                        .background(Color.sonjuDivider)
                        .padding(.top, 12)

                    if let rating = item.rating {
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 13))
                                    .foregroundColor(star <= rating ? Color(hex: "#FFB300") : Color.sonjuDivider)
                            }
                            Text("평가 완료")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                                .padding(.leading, 4)
                        }
                        .padding(.top, 10)
                    } else {
                        NavigationLink(destination: MentorRatingView(booking: item)) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.leadinghalf.filled")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#FFB300"))
                                Text("멘토 평가하기")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(.sonjuSecondary)
                            }
                            .padding(.top, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
