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

    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""

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
                            }
                        }
                    }

                    HStack(spacing: 4) {
                        Text("아직 계정이 없으신가요?")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                        Button {
                            navigateToSignUp = true
                        } label: {
                            Text("회원가입")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuPrimary)
                                .underline()
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
    }
}
