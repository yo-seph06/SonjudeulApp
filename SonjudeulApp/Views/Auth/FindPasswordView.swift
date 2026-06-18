import SwiftUI

struct FindPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var identifier = ""
    @State private var phone = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var foundUser: User? = nil
    @State private var step: Step = .verify
    @State private var errorMessage = ""
    @State private var showSuccess = false

    enum Step { case verify, reset }

    var canVerify: Bool { !identifier.isEmpty && phone.count >= 10 }
    var canReset: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("비밀번호 찾기")
                                .font(.sonjuLargeTitle)
                                .foregroundColor(.sonjuText)
                            Text(step == .verify
                                 ? "가입 시 사용한 아이디(이메일)와 휴대폰 번호를 입력해주세요"
                                 : "새로운 비밀번호를 설정해주세요")
                                .font(.sonjuBody)
                                .foregroundColor(.sonjuSecondary)
                        }
                        .padding(.top, 24)

                        if step == .verify {
                            verifySection
                        } else {
                            resetSection
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }

                if showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if step == .reset {
                            withAnimation { step = .verify }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.sonjuText)
                    }
                }
            }
        }
    }

    private var verifySection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                fieldView(label: "이메일 또는 아이디", placeholder: "가입 시 사용한 이메일/아이디", text: $identifier, keyboard: .emailAddress)
                fieldView(label: "휴대폰 번호", placeholder: "01012345678 (숫자만)", text: $phone, keyboard: .phonePad)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.sonjuCaption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            AmberButton(title: "본인 확인", disabled: !canVerify) {
                withAnimation(.easeOut(duration: 0.3)) {
                    if let user = UserStore.shared.findUserByIdentifierAndPhone(identifier: identifier, phone: phone) {
                        foundUser = user
                        errorMessage = ""
                        step = .reset
                    } else {
                        errorMessage = "일치하는 계정이 없어요. 아이디 또는 휴대폰 번호를 확인해주세요"
                    }
                }
            }
        }
    }

    private var resetSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                secureFieldView(label: "새 비밀번호", placeholder: "6자리 이상 입력", text: $newPassword)
                secureFieldView(label: "비밀번호 확인", placeholder: "다시 한 번 입력", text: $confirmPassword)
            }

            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("비밀번호가 일치하지 않아요")
                    .font(.sonjuCaption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            AmberButton(title: "비밀번호 변경", disabled: !canReset) {
                if let user = foundUser {
                    UserStore.shared.resetPassword(userId: user.id, newPassword: newPassword)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.sonjuSuccess)
                Text("비밀번호가 변경됐어요!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.sonjuText)
                Text("새 비밀번호로 로그인해주세요")
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuSecondary)
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
            .scaleEffect(showSuccess ? 1 : 0.8)
            .opacity(showSuccess ? 1 : 0)
        }
    }

    private func fieldView(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
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
    }

    private func secureFieldView(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
            SecureField(placeholder, text: text)
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
    }
}

#Preview {
    FindPasswordView()
}
