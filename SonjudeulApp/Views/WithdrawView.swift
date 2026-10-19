import SwiftUI

struct WithdrawView: View {
    @EnvironmentObject var auth: AuthViewModel

    @State private var password = ""
    @State private var agreed = false
    @State private var showConfirm = false
    @State private var errorMessage = ""
    @State private var completed: (requestedAt: Date, scheduledAt: Date)? = nil

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
                            Text("회원 탈퇴를 신청하면 계정은 즉시 비활성화되며, \(DeletionPolicy.gracePeriodDays)일간 탈퇴 유예기간이 적용됩니다. \(DeletionPolicy.gracePeriodDays)일 이내 다시 로그인하면 계정을 복구할 수 있습니다. \(DeletionPolicy.gracePeriodDays)일이 지나면 계정과 관련 데이터가 영구적으로 삭제되어 복구할 수 없습니다.")
                                .font(.sonjuBody)
                                .foregroundColor(.sonjuText)
                                .fixedSize(horizontal: false, vertical: true)
                            Divider().background(Color.sonjuDivider)
                            noticeRow("유예기간 동안에는 로그인 후 계정 복구만 할 수 있어요.")
                            noticeRow("영구 삭제 시 회원정보, 예약, 일정, 리포트가 삭제돼요.")
                            noticeRow("완료된 방문 기록은 이름 등 개인정보 없이 통계용으로만 남아요.")
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

            if let completed {
                completionOverlay(requestedAt: completed.requestedAt, scheduledAt: completed.scheduledAt)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(completed != nil)
        .alert("회원 탈퇴", isPresented: $showConfirm) {
            Button("취소", role: .cancel) {}
            Button("탈퇴하기", role: .destructive) { requestDeletion() }
        } message: {
            Text("탈퇴 신청 후 \(DeletionPolicy.gracePeriodDays)일 동안은 계정을 복구할 수 있습니다.\n\n\(DeletionPolicy.gracePeriodDays)일이 지나면 계정과 관련된 데이터가 영구 삭제되며 복구할 수 없습니다.\n\n정말 탈퇴하시겠습니까?")
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

    private func completionOverlay(requestedAt: Date, scheduledAt: Date) -> some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.sonjuPrimary)
                Text("탈퇴 신청이 완료되었어요")
                    .font(.sonjuHeadline)
                    .foregroundColor(.sonjuText)
                VStack(alignment: .leading, spacing: 6) {
                    Text("탈퇴 신청일: \(DeletionPolicy.dateTimeText(requestedAt))")
                    Text("영구 삭제 예정일: \(DeletionPolicy.dateTimeText(scheduledAt))")
                }
                .font(.sonjuCaption)
                .foregroundColor(.sonjuText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.sonjuBackground)
                .cornerRadius(12)
                Text("영구 삭제 예정일 전에 다시 로그인하면 계정을 복구할 수 있어요.")
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuSecondary)
                    .multilineTextAlignment(.center)
                AmberButton(title: "확인") { auth.logout() }
            }
            .padding(28)
            .background(Color.sonjuCard)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 20)
            .padding(.horizontal, 24)
        }
    }

    private func requestDeletion() {
        do {
            let pending = try auth.requestDeletion(password: password)
            guard let requestedAt = pending.deletionRequestedAt,
                  let scheduledAt = pending.scheduledDeletionAt else { auth.logout(); return }
            withAnimation { completed = (requestedAt, scheduledAt) }
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
    }
}
