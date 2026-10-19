import SwiftUI

/// 재인증이 필요한 관리자 작업 (확인 창에서 '확인'을 누른 뒤 실행할 작업)
struct PendingAdminAction: Identifiable {
    let id = UUID()
    let title: String
    let target: String
    let run: () -> Void
}

extension View {
    /// pending에 작업이 들어오면 관리자 비밀번호 재확인 창을 띄우고, 성공한 경우에만 작업을 실행한다.
    func adminReauth(_ pending: Binding<PendingAdminAction?>) -> some View {
        modifier(AdminReauthModifier(pending: pending))
    }
}

/// 최근 5분 안에 재인증했다면 바로 실행하고, 아니면 재인증 창을 띄운다.
func performWithAdminReauth(_ action: PendingAdminAction, adminId: UUID?,
                            pending: Binding<PendingAdminAction?>) {
    if AdminReauthSession.shared.isFresh(for: adminId) {
        action.run()
    } else {
        pending.wrappedValue = action
    }
}

private struct AdminReauthModifier: ViewModifier {
    @Binding var pending: PendingAdminAction?
    @State private var verifiedAction: PendingAdminAction?

    func body(content: Content) -> some View {
        content.sheet(item: $pending, onDismiss: {
            // 창이 완전히 닫힌 뒤 실행해야 작업 후 화면 이동(dismiss)이 겹치지 않는다
            if let action = verifiedAction {
                verifiedAction = nil
                action.run()
            }
        }) { action in
            AdminReauthSheet(action: action) { verifiedAction = action }
        }
    }
}

private struct AdminReauthSheet: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    let action: PendingAdminAction
    let onVerified: () -> Void

    @State private var password = ""
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("관리자 재확인", systemImage: "lock.shield.fill")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuDeep)
                                Text(action.title)
                                    .font(.sonjuBody.weight(.semibold))
                                    .foregroundColor(.sonjuText)
                                Text(action.target)
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("중요한 작업이라 관리자 비밀번호를 한 번 더 확인해요. 확인 후 5분 동안은 다시 묻지 않아요.")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        SecureField("관리자 비밀번호", text: $password)
                            .font(.sonjuBody)
                            .textContentType(.password)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sonjuDivider, lineWidth: 1))

                        if let message {
                            Text(message)
                                .font(.sonjuCaption)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        AmberButton(title: "확인", disabled: password.isEmpty) { verify() }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("비밀번호 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.sonjuText)
                }
            }
        }
    }

    private func verify() {
        let result = AdminReauthSession.shared.verify(adminId: auth.currentUser?.id, password: password)
        password = ""   // 입력한 비밀번호는 화면 상태에도 남기지 않는다
        switch result {
        case .success:
            onVerified()
            dismiss()
        case .wrongPassword(let remaining):
            message = "비밀번호가 올바르지 않아요. (\(remaining)번 더 틀리면 5분 동안 잠겨요)"
        case .locked(let until):
            message = "비밀번호를 여러 번 틀려 \(DeletionPolicy.dateTimeText(until))까지 재확인이 잠겼어요."
            AdminAlertStore.shared.record(
                key: "reauth-lock:\(Int(until.timeIntervalSince1970))", category: .security,
                title: "관리자 재확인 잠금",
                message: "관리자 비밀번호 재확인을 \(AdminReauthSession.maxFailures)번 연속 틀려 \(DeletionPolicy.dateTimeText(until))까지 잠겼어요. 본인이 아니라면 비밀번호를 바꿔주세요.")
        case .notAuthorized:
            message = "관리자 권한을 확인할 수 없어요. 다시 로그인해주세요."
        }
    }
}
