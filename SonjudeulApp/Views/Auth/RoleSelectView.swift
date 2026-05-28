import SwiftUI

struct RoleSelectView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var navigateToLogin = false
    @State private var navigateToSignUp = false
    @State private var selectedRole: UserRole = .child

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.sonjuPrimary)
                                .font(.system(size: 28))
                            Text("손주들")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.sonjuText)
                        }
                        Text("효도를 일상의 서비스로")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 48)

                    VStack(spacing: 16) {
                        RoleCard(
                            icon: "gift.fill",
                            title: "자녀로 시작하기",
                            description: "부모님께 스마트폰 교육을\n선물해드려요",
                            role: .child,
                            selectedRole: $selectedRole,
                            action: {
                                selectedRole = .child
                                navigateToLogin = true
                            }
                        )

                        RoleCard(
                            icon: "graduationcap.fill",
                            title: "멘토로 시작하기",
                            description: "방문 교육으로 수익도 쌓고\n보람도 느껴요",
                            role: .mentor,
                            selectedRole: $selectedRole,
                            action: {
                                selectedRole = .mentor
                                navigateToLogin = true
                            }
                        )

                        // 회원가입 링크
                        HStack(spacing: 4) {
                            Text("아직 계정이 없으신가요?")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                            Button {
                                navigateToSignUp = true
                            } label: {
                                Text("회원가입하기")
                                    .font(.sonjuCaption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.sonjuPrimary)
                                    .underline()
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView(role: selectedRole)
            }
            .navigationDestination(isPresented: $navigateToSignUp) {
                SignUpView()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    RoleSelectView()
        .environmentObject(AuthViewModel())
}

struct RoleCard: View {
    let icon: String
    let title: String
    let description: String
    let role: UserRole
    @Binding var selectedRole: UserRole
    let action: () -> Void

    var isSelected: Bool { selectedRole == role }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.sonjuPrimary.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.sonjuPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.sonjuHeadline)
                        .foregroundColor(.sonjuText)
                    Text(description)
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.sonjuSecondary)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.sonjuPrimary, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PressButtonStyle())
    }
}
