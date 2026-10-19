import SwiftUI

#Preview {
    NavigationStack {
        LoginView(role: .child)
            .environmentObject(AuthViewModel())
    }
}

struct LoginView: View {
    let role: UserRole
    @EnvironmentObject var auth: AuthViewModel
    @State private var navigateToSignUp = false
    @State private var showFindId = false
    @State private var showFindPassword = false

    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var pendingDeletion: (requestedAt: Date, scheduledAt: Date)? = nil
    @State private var showRestoreAlert = false

    var canLogin: Bool {
        !identifier.isEmpty && password.count >= 6
    }

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(role == .child ? "자녀 로그인" : "멘토 로그인")
                            .font(.sonjuLargeTitle)
                            .foregroundColor(.sonjuText)
                        Text("이메일 또는 아이디로 시작하세요")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("이메일 또는 아이디")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                            TextField("이메일 또는 아이디 입력", text: $identifier)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("비밀번호")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                            SecureField("비밀번호를 입력하세요", text: $password)
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

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.sonjuCaption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }
                    }

                    AmberButton(title: "로그인", disabled: !canLogin) {
                        withAnimation {
                            switch auth.login(identifier: identifier, password: password, role: role) {
                            case .success:
                                break
                            case .wrongCredentials:
                                errorMessage = "아이디(이메일) 또는 비밀번호가 올바르지 않아요"
                            case .wrongRole:
                                let roleLabel = role == .child ? "자녀" : "멘토"
                                errorMessage = "\(roleLabel) 계정이 아니에요. 올바른 로그인 방식을 선택해주세요"
                            case let .pendingDeletion(requestedAt, scheduledAt):
                                errorMessage = ""
                                pendingDeletion = (requestedAt, scheduledAt)
                                showRestoreAlert = true
                            }
                        }
                    }

                    // 아이디 찾기 | 비밀번호 찾기
                    HStack(spacing: 0) {
                        Button { showFindId = true } label: {
                            Text("아이디 찾기")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                        }
                        Text("  |  ")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuDivider)
                        Button { showFindPassword = true } label: {
                            Text("비밀번호 찾기")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                        }
                        Text("  |  ")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuDivider)
                        Button { navigateToSignUp = true } label: {
                            Text("회원가입")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showFindId) {
            FindIdView()
        }
        .sheet(isPresented: $showFindPassword) {
            FindPasswordView()
        }
        .alert("탈퇴한 계정입니다", isPresented: $showRestoreAlert) {
            Button("취소", role: .cancel) {}
            Button("복구") { restoreAccount() }
        } message: {
            if let pending = pendingDeletion {
                Text("계정을 복구하시겠습니까?\n\n탈퇴 신청일: \(DeletionPolicy.dateTimeText(pending.requestedAt))\n영구 삭제 예정일: \(DeletionPolicy.dateTimeText(pending.scheduledAt))\n(\(DeletionPolicy.remainingLabel(until: pending.scheduledAt)))")
            } else {
                Text("계정을 복구하시겠습니까?")
            }
        }
    }

    private func restoreAccount() {
        switch auth.restoreAccount(identifier: identifier, password: password, role: role) {
        case .success:
            errorMessage = ""
        default:
            // 그 사이 유예기간이 끝났거나 정보가 바뀐 경우
            errorMessage = "계정을 복구할 수 없어요. 탈퇴 유예기간이 지났을 수 있어요"
        }
    }
}
