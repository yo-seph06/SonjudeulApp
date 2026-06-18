import SwiftUI

struct FindIdView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var result: String? = nil
    @State private var errorMessage = ""
    @State private var searched = false

    var canSearch: Bool { !name.isEmpty && phone.count >= 10 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("아이디 찾기")
                                .font(.sonjuLargeTitle)
                                .foregroundColor(.sonjuText)
                            Text("가입할 때 입력한 이름과 휴대폰 번호를 입력해주세요")
                                .font(.sonjuBody)
                                .foregroundColor(.sonjuSecondary)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 16) {
                            SonjuInputField(label: "이름", placeholder: "가입 시 입력한 이름", text: $name)
                            SonjuInputField(label: "휴대폰 번호", placeholder: "01012345678 (숫자만)", text: $phone, keyboard: .phonePad)
                        }

                        if searched {
                            SonjuCard {
                                if let id = result {
                                    VStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(.sonjuSuccess)
                                        Text("아이디를 찾았어요")
                                            .font(.sonjuBody)
                                            .foregroundColor(.sonjuSecondary)
                                        Text(id)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.sonjuText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(.red.opacity(0.8))
                                        Text("일치하는 계정이 없어요")
                                            .font(.sonjuBody)
                                            .foregroundColor(.sonjuSecondary)
                                        Text("이름 또는 휴대폰 번호를 확인해주세요")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(.horizontal, 0)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }

                        AmberButton(title: "아이디 찾기", disabled: !canSearch) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                let user = UserStore.shared.findUserByNameAndPhone(name: name, phone: phone)
                                if let user {
                                    result = maskEmail(user.email)
                                } else {
                                    result = nil
                                }
                                searched = true
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.sonjuText)
                    }
                }
            }
        }
    }

    private func maskEmail(_ email: String) -> String {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return email }
        let local = String(parts[0])
        let domain = String(parts[1])
        let visible = local.prefix(2)
        let masked = String(repeating: "*", count: max(local.count - 2, 3))
        return "\(visible)\(masked)@\(domain)"
    }
}

private struct SonjuInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
            TextField(placeholder, text: $text)
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
}

#Preview {
    FindIdView()
}
