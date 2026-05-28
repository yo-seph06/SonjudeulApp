import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var phone: String
    @State private var university: String
    @State private var profileItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage?
    @State private var showSuccess = false
    @State private var errorMessage = ""

    private let isMentor: Bool

    init(user: User) {
        _name = State(initialValue: user.name)
        _phone = State(initialValue: user.phone)
        _university = State(initialValue: user.university ?? "")
        isMentor = user.role == .mentor
        if let data = user.profileImageData, let img = UIImage(data: data) {
            _profileImage = State(initialValue: img)
        } else {
            _profileImage = State(initialValue: nil)
        }
    }

    private var canSave: Bool {
        !name.isEmpty &&
        phone.count >= 10 &&
        (isMentor ? !university.isEmpty : true)
    }

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {

                    // 프로필 사진
                    VStack(spacing: 8) {
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
                                            .fill(Color.sonjuPrimary.opacity(0.2))
                                            .frame(width: 90, height: 90)
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 36)
                                            .foregroundColor(.sonjuPrimary)
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
                        Text("사진 변경")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    EditField(label: "이름", placeholder: "홍길동", text: $name)

                    if isMentor {
                        EditField(label: "소속 대학교 및 학과",
                                  placeholder: "예) 연세대학교 컴퓨터공학과 3학년",
                                  text: $university)
                    }

                    EditField(label: "전화번호", placeholder: "010-0000-0000",
                              text: $phone, keyboard: .phonePad)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.sonjuCaption)
                            .foregroundColor(.red)
                    }

                    AmberButton(title: "저장하기", disabled: !canSave) {
                        save()
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            if showSuccess {
                Color.black.opacity(0.4).ignoresSafeArea().transition(.opacity)
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundColor(.sonjuPrimary)
                    Text("프로필이 수정되었어요!")
                        .font(.sonjuLargeTitle)
                        .foregroundColor(.sonjuText)
                }
                .padding(40)
                .background(Color.sonjuCard)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.15), radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("프로필 수정")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.4), value: showSuccess)
    }

    private func save() {
        guard var updated = auth.currentUser else { return }
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.phone = phone.trimmingCharacters(in: .whitespaces)
        if isMentor {
            updated.university = university.trimmingCharacters(in: .whitespaces)
        }
        if let img = profileImage {
            updated.profileImageData = img.jpegData(compressionQuality: 0.7)
        }
        auth.updateCurrentUser(updated)
        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }
}

#Preview {
    let user = User(name: "김자녀", username: "child1", email: "child@test.com",
                    password: "test123", phone: "01012345678",
                    role: .child, birthDate: Date(), gender: .female)
    return NavigationStack {
        ProfileEditView(user: user)
            .environmentObject(AuthViewModel())
    }
}

private struct EditField: View {
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
