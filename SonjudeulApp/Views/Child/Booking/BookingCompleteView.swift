import SwiftUI

struct BookingCompleteView: View {
    @ObservedObject var bookingVM: BookingViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showIcon = false
    @State private var didRecord = false
    @State private var showShare = false

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 (E) a h시"
        return f.string(from: bookingVM.visitDate)
    }

    private var planName: String {
        bookingVM.selectedPlan == .subscription ? "안심 정기구독" : "원데이 효도"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(Color.sonjuPrimary.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(showIcon ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5), value: showIcon)

                    Circle()
                        .strokeBorder(Color.sonjuPrimary, lineWidth: 3)
                        .frame(width: 110, height: 110)
                        .scaleEffect(showIcon ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: showIcon)

                    Image(systemName: "person.fill.questionmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.sonjuPrimary)
                        .scaleEffect(showIcon ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.25), value: showIcon)
                }
                .padding(.top, 48)

                VStack(spacing: 8) {
                    Text("예약 신청이 완료되었어요! 🎉")
                        .font(.sonjuLargeTitle)
                        .foregroundColor(.sonjuText)
                        .multilineTextAlignment(.center)
                    Text("멘토가 수락하면 매칭이 확정돼요")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuSecondary)
                }

                // 안내 배너
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.sonjuPrimary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("멘토를 찾고 있습니다")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuPrimary)
                        Text("매칭 완료 시 알림으로 알려드려요")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.sonjuPrimary.opacity(0.08))
                .cornerRadius(14)
                .padding(.horizontal, 24)

                // 요약 카드
                SonjuCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SummaryRow(label: "플랜", value: planName)
                        Divider().background(Color.sonjuDivider)
                        SummaryRow(label: "방문 날짜", value: formattedDate)
                        Divider().background(Color.sonjuDivider)
                        SummaryRow(label: "부모님 성함", value: bookingVM.parentName.isEmpty ? "미입력" : bookingVM.parentName)
                        Divider().background(Color.sonjuDivider)
                        SummaryRow(label: "담당 멘토", value: "매칭 중...")
                    }
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    Button {
                        showShare = true
                    } label: {
                        Text("공유하기")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.sonjuPrimary.opacity(0.12))
                            .cornerRadius(14)
                    }
                    .buttonStyle(PressButtonStyle())

                    AmberButton(title: "홈으로 돌아가기") {
                        bookingVM.reset()
                        dismiss()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: ["손주들 앱에서 예약을 완료했어요! 📅\n방문일: \(formattedDate)\n플랜: \(planName)"])
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showIcon = true
            }
            if !didRecord {
                didRecord = true
                bookingStore.add(BookingRecord(
                    date: formattedDate,
                    rawDate: bookingVM.visitDate,
                    plan: planName,
                    status: "멘토 찾는 중",
                    childId: auth.currentUser?.id
                ))
            }
        }
    }
}

#Preview {
    let vm = BookingViewModel()
    vm.parentName = "홍길순"
    return BookingCompleteView(bookingVM: vm)
        .environmentObject(BookingStore())
        .environmentObject(AuthViewModel())
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
            Spacer()
            Text(value)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
                .fontWeight(.medium)
        }
    }
}
