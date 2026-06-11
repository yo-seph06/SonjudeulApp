import SwiftUI

struct BookingRequesterProfileView: View {
    let booking: BookingRecord
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @Environment(\.dismiss) private var dismiss
    @State private var showAcceptAlert = false

    private var requester: User? {
        guard let id = booking.childId else { return nil }
        return UserStore.shared.findUserById(id)
    }

    private var age: Int? {
        guard let user = requester else { return nil }
        return Calendar.current.dateComponents([.year], from: user.birthDate, to: Date()).year
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // 프로필 사진 + 이름
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.sonjuPrimary.opacity(0.15))
                                    .frame(width: 96, height: 96)
                                if let data = requester?.profileImageData,
                                   let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 96, height: 96)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.sonjuPrimary)
                                }
                            }
                            Text(requester?.name ?? "알 수 없음")
                                .font(.sonjuTitle)
                                .foregroundColor(.sonjuText)
                            BadgeView(text: "신청자", color: Color(hex: "#FF9800"))
                        }
                        .padding(.top, 8)

                        // 기본 정보
                        SonjuCard {
                            VStack(spacing: 0) {
                                ProfileInfoRow(
                                    icon: "person.fill",
                                    label: "성별",
                                    value: requester?.gender.rawValue ?? "-"
                                )
                                Divider().background(Color.sonjuDivider)
                                ProfileInfoRow(
                                    icon: "calendar",
                                    label: "나이",
                                    value: age.map { "\($0)세" } ?? "-"
                                )
                                Divider().background(Color.sonjuDivider)
                                ProfileInfoRow(
                                    icon: "phone.fill",
                                    label: "연락처",
                                    value: requester?.phone ?? "-"
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // 신청 내용
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("신청 내용", systemImage: "doc.text.fill")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuText)

                                Divider().background(Color.sonjuDivider)

                                ProfileInfoRow(
                                    icon: "book.fill",
                                    label: "교육 플랜",
                                    value: booking.plan
                                )
                                Divider().background(Color.sonjuDivider)
                                ProfileInfoRow(
                                    icon: "clock.fill",
                                    label: "방문 일시",
                                    value: booking.date
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // 안내 문구
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.sonjuPrimary.opacity(0.6))
                                .font(.system(size: 14))
                            Text("수락 시 신청자에게 매칭 알림이 전송됩니다")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                        }
                        .padding(.horizontal, 28)

                        // 수락 버튼
                        AmberButton(title: "수락하기") {
                            showAcceptAlert = true
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("신청자 프로필")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.sonjuPrimary)
                }
            }
            .alert("신청 수락", isPresented: $showAcceptAlert) {
                Button("취소", role: .cancel) {}
                Button("수락") {
                    if let mentorId = auth.currentUser?.id,
                       let mentorName = auth.currentUser?.name {
                        bookingStore.acceptBooking(id: booking.id, mentorId: mentorId, mentorName: mentorName)
                    }
                    dismiss()
                }
            } message: {
                Text("'\(requester?.name ?? "신청자")'님의 예약을 수락하시겠어요?\n수락 시 매칭 알림이 전송됩니다.")
            }
        }
    }
}

// MARK: - 정보 행

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.sonjuPrimary)
                .font(.system(size: 15))
                .frame(width: 20)
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
                .frame(width: 60, alignment: .leading)
            Spacer()
            Text(value)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }
}
