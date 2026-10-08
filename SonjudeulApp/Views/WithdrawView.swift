import SwiftUI

struct WithdrawView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var reportStore: ReportStore
    @EnvironmentObject var scheduleStore: ScheduleStore

    @State private var password = ""
    @State private var agreed = false
    @State private var showConfirm = false
    @State private var errorMessage = ""

    private var canWithdraw: Bool { agreed && password.count >= 6 }

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("회원 탈퇴")
                            .font(.sonjuLargeTitle)
                            .foregroundColor(.sonjuText)
                        Text("탈퇴 전에 아래 내용을 꼭 확인해주세요")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                    }
                    .padding(.top, 8)

                    SonjuCard {
                        VStack(alignment: .leading, spacing: 12) {
                            noticeRow("탈퇴한 계정으로는 다시 로그인할 수 없어요.")
                            noticeRow("진행 중인 예약, 일정, 리포트가 삭제돼요.")
                            noticeRow("연락처·이메일·프로필 사진 등 개인정보가 삭제돼요.")
                            noticeRow("사용하던 아이디는 다시 가입에 사용할 수 없어요.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("비밀번호 확인")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                        SecureField("현재 비밀번호를 입력하세요", text: $password)
                            .font(.sonjuBody)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.sonjuDivider, lineWidth: 1)
                            )
                    }

                    Button { agreed.toggle() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: agreed ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreed ? .sonjuPrimary : .sonjuSecondary)
                                .font(.system(size: 20))
                            Text("안내 사항을 모두 확인했어요")
                                .font(.sonjuBody)
                                .foregroundColor(.sonjuText)
                            Spacer()
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.sonjuCaption)
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }

                    Button {
                        showConfirm = true
                    } label: {
                        Text("회원 탈퇴")
                            .font(.sonjuHeadline)
                            .foregroundColor(canWithdraw ? .white : .sonjuSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(canWithdraw ? Color.red : Color.sonjuDivider)
                            .cornerRadius(14)
                    }
                    .buttonStyle(PressButtonStyle())
                    .disabled(!canWithdraw)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("회원 탈퇴", isPresented: $showConfirm) {
            Button("취소", role: .cancel) {}
            Button("탈퇴", role: .destructive) { withdraw() }
        } message: {
            Text("정말 회원 탈퇴를 하시겠습니까?")
        }
    }

    private func noticeRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.sonjuPrimary)
                .font(.system(size: 14))
                .padding(.top, 1)
            Text(text)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func withdraw() {
        guard let role = auth.currentUser?.role else { return }
        do {
            // 본인 확인 후 탈퇴 처리 + 로그아웃
            let id = try auth.withdraw(password: password)
            // 탈퇴한 회원의 데이터가 다른 회원에게 보이지 않도록 정리
            if role == .mentor {
                bookingStore.releaseBookings(forWithdrawnMentor: id)
            } else {
                bookingStore.removeData(forWithdrawnChild: id)
                reportStore.removeReports(forChild: id)
            }
            scheduleStore.removeEvents(forOwner: id)
        } catch AccountError.wrongPassword {
            errorMessage = "비밀번호가 올바르지 않아요"
        } catch AccountError.adminProtected {
            errorMessage = "관리자 계정은 탈퇴할 수 없어요"
        } catch {
            errorMessage = "탈퇴 처리 중 문제가 발생했어요. 다시 시도해주세요"
        }
    }
}

#Preview {
    NavigationStack {
        WithdrawView()
            .environmentObject(AuthViewModel())
            .environmentObject(BookingStore())
            .environmentObject(ReportStore())
            .environmentObject(ScheduleStore())
    }
}
