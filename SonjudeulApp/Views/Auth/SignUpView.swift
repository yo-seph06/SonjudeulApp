import SwiftUI
import PhotosUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedRole: UserRole = .child
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var phone = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    @State private var gender: Gender? = nil
    @State private var profileItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var university = ""
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var agreePrivacy = false
    @State private var agreeTerms = false
    @State private var showPrivacySheet = false
    @State private var showTermsSheet = false

    var passwordsMatch: Bool { password == passwordConfirm }

    var canSubmit: Bool {
        !name.isEmpty &&
        username.count >= 4 &&
        !email.isEmpty && email.contains("@") &&
        password.count >= 6 &&
        passwordsMatch &&
        phone.count >= 10 &&
        gender != nil &&
        agreePrivacy &&
        agreeTerms &&
        (selectedRole == .child || !university.isEmpty)
    }

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("회원가입")
                            .font(.sonjuLargeTitle)
                            .foregroundColor(.sonjuText)
                        Text("손주들 서비스에 오신 걸 환영해요")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                    }
                    .padding(.top, 8)

                    // 역할 선택
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("역할 선택")
                        Picker("역할", selection: $selectedRole) {
                            Text("자녀").tag(UserRole.child)
                            Text("멘토").tag(UserRole.mentor)
                        }
                        .pickerStyle(.segmented)
                    }

                    // 프로필 사진
                    VStack(spacing: 6) {
                        PhotosPicker(selection: $profileItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let img = profileImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.sonjuDivider)
                                            .frame(width: 90, height: 90)
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 36)
                                            .foregroundColor(.sonjuSecondary)
                                    }
                                }
                                ZStack {
                                    Circle()
                                        .fill(Color.sonjuPrimary)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .onChange(of: profileItem) { item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    profileImage = uiImage
                                }
                            }
                        }
                        Text("프로필 사진 (선택)")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    // 이름
                    InputField(label: "이름", placeholder: "홍길동", text: $name)

                    // 대학교 (멘토 전용)
                    if selectedRole == .mentor {
                        InputField(label: "소속 대학교 및 학과",
                                   placeholder: "예) 연세대학교 컴퓨터공학과 3학년",
                                   text: $university)
                    }

                    // 아이디
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("아이디 (4자 이상)")
                        TextField("영문, 숫자 조합", text: $username)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.sonjuBody)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        username.isEmpty ? Color.sonjuDivider :
                                            (username.count >= 4 ? Color.sonjuSuccess : Color.red),
                                        lineWidth: 1
                                    )
                            )
                        if !username.isEmpty && username.count < 4 {
                            Text("아이디는 4자 이상이어야 해요")
                                .font(.sonjuCaption)
                                .foregroundColor(.red)
                        }
                    }

                    // 이메일
                    InputField(label: "이메일", placeholder: "example@email.com",
                               text: $email, keyboard: .emailAddress, autocap: false)

                    // 비밀번호
                    InputField(label: "비밀번호 (6자리 이상)", placeholder: "••••••",
                               text: $password, isSecure: true)

                    // 비밀번호 확인
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("비밀번호 확인")
                        SecureField("비밀번호를 다시 입력하세요", text: $passwordConfirm)
                            .font(.sonjuBody)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        passwordConfirm.isEmpty ? Color.sonjuDivider :
                                            (passwordsMatch ? Color.sonjuSuccess : Color.red),
                                        lineWidth: 1
                                    )
                            )
                        if !passwordConfirm.isEmpty && !passwordsMatch {
                            Text("비밀번호가 일치하지 않아요")
                                .font(.sonjuCaption)
                                .foregroundColor(.red)
                        }
                    }

                    // 전화번호
                    InputField(label: "전화번호", placeholder: "010-0000-0000",
                               text: $phone, keyboard: .phonePad)

                    // 생년월일
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("생년월일")
                        HStack {
                            DatePicker("", selection: $birthDate,
                                       in: ...Date(),
                                       displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.sonjuDivider, lineWidth: 1)
                        )
                    }

                    // 성별
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("성별")
                        HStack(spacing: 12) {
                            ForEach(Gender.allCases, id: \.self) { g in
                                Button {
                                    gender = g
                                } label: {
                                    Text(g.rawValue)
                                        .font(.sonjuBody)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .foregroundColor(gender == g ? .white : .sonjuText)
                                        .background(gender == g ? Color.sonjuPrimary : Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    gender == g ? Color.sonjuPrimary : Color.sonjuDivider,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(PressButtonStyle())
                            }
                        }
                    }

                    // 약관 동의
                    VStack(spacing: 0) {
                        // 전체 동의
                        Button {
                            let all = agreePrivacy && agreeTerms
                            agreePrivacy = !all
                            agreeTerms = !all
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: (agreePrivacy && agreeTerms) ? "checkmark.square.fill" : "square")
                                    .foregroundColor((agreePrivacy && agreeTerms) ? .sonjuPrimary : .sonjuSecondary)
                                    .font(.system(size: 20))
                                Text("전체 동의")
                                    .font(.sonjuBody)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.sonjuText)
                                Spacer()
                            }
                            .padding(16)
                        }

                        Divider().background(Color.sonjuDivider)

                        // 개인정보 처리방침
                        HStack(spacing: 10) {
                            Button { agreePrivacy.toggle() } label: {
                                Image(systemName: agreePrivacy ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreePrivacy ? .sonjuPrimary : .sonjuSecondary)
                                    .font(.system(size: 18))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("[필수] 개인정보 처리방침 동의")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuText)
                                Text("이름·연락처·계좌 등을 수집하며, 탈퇴 시 또는 법령 기간까지 보관합니다.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.sonjuSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Button("보기") { showPrivacySheet = true }
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider().background(Color.sonjuDivider)

                        // 서비스 이용약관
                        HStack(spacing: 10) {
                            Button { agreeTerms.toggle() } label: {
                                Image(systemName: agreeTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreeTerms ? .sonjuPrimary : .sonjuSecondary)
                                    .font(.system(size: 18))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("[필수] 서비스 이용약관 동의")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuText)
                                Text("허위정보 등록·직거래 금지, 24시간 전 취소 시 전액 환불, 콘텐츠 무단 사용 금지에 동의합니다.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.sonjuSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Button("보기") { showTermsSheet = true }
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.sonjuDivider, lineWidth: 1)
                    )

                    // 에러
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.sonjuCaption)
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }

                    AmberButton(title: "가입하기", disabled: !canSubmit) {
                        withAnimation { signUp() }
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPrivacySheet) {
            NavigationStack { PrivacyConsentView() }
        }
        .sheet(isPresented: $showTermsSheet) {
            NavigationStack { TermsOfServiceView() }
        }
        .alert("가입 완료!", isPresented: $showSuccess) {
            Button("로그인하러 가기") { dismiss() }
        } message: {
            Text("회원가입이 완료되었어요.\n아이디 또는 이메일로 로그인해주세요.")
        }
    }

    private func signUp() {
        guard canSubmit, let gender = gender else { return }

        if UserStore.shared.emailExists(email) {
            errorMessage = "이미 사용 중인 이메일이에요"
            return
        }
        if UserStore.shared.usernameExists(username) {
            errorMessage = "이미 사용 중인 아이디에요"
            return
        }

        let imageData = profileImage?.jpegData(compressionQuality: 0.7)
        let user = User(
            name: name,
            username: username,
            email: email,
            password: password,
            phone: phone,
            role: selectedRole,
            birthDate: birthDate,
            gender: gender,
            profileImageData: imageData,
            university: selectedRole == .mentor ? university : nil
        )
        UserStore.shared.register(user)
        showSuccess = true
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}

// MARK: - 공통 컴포넌트

private struct FieldLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.sonjuCaption)
            .foregroundColor(.sonjuSecondary)
    }
}

private struct InputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocap: Bool = true
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(label)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(autocap ? .sentences : .never)
                        .autocorrectionDisabled()
                }
            }
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
