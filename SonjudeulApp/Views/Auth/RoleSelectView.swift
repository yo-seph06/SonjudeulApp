import SwiftUI

struct RoleSelectView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var navigateToLogin = false
    @State private var navigateToSignUp = false
    @State private var selectedRole: UserRole = .child
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 그라디언트
                LinearGradient(
                    colors: [Color(hex: "#FFF8ED"), Color(hex: "#FFE4B2")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 배경 장식 원
                Circle()
                    .fill(Color.sonjuPrimary.opacity(0.07))
                    .frame(width: 340, height: 340)
                    .offset(x: 140, y: -260)

                Circle()
                    .fill(Color.sonjuPrimary.opacity(0.05))
                    .frame(width: 260, height: 260)
                    .offset(x: -130, y: 340)

                VStack(spacing: 0) {
                    Spacer()

                    // 로고 섹션
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.sonjuPrimary.opacity(0.13))
                                .frame(width: 96, height: 96)
                            Circle()
                                .fill(Color.sonjuPrimary.opacity(0.08))
                                .frame(width: 116, height: 116)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 42))
                                .foregroundColor(.sonjuPrimary)
                        }
                        .scaleEffect(appeared ? 1 : 0.6)
                        .opacity(appeared ? 1 : 0)

                        VStack(spacing: 6) {
                            Text("손주들")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.sonjuText)
                            Text("효도를 일상의 서비스로")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.sonjuSecondary)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                    }
                    .multilineTextAlignment(.center)

                    Spacer()

                    // 역할 선택 카드
                    VStack(spacing: 14) {
                        Text("어떻게 시작하실 건가요?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.sonjuSecondary)
                            .opacity(appeared ? 1 : 0)

                        HStack(spacing: 14) {
                            RoleCardNew(
                                icon: "gift.fill",
                                title: "자녀",
                                description: "부모님께\n스마트폰 교육을\n선물해드려요",
                                color: Color(hex: "#F5A623"),
                                isSelected: selectedRole == .child
                            ) {
                                selectedRole = .child
                                navigateToLogin = true
                            }

                            RoleCardNew(
                                icon: "graduationcap.fill",
                                title: "멘토",
                                description: "방문 교육으로\n수익도 쌓고\n보람도 느껴요",
                                color: Color(hex: "#5C9EF5"),
                                isSelected: selectedRole == .mentor
                            ) {
                                selectedRole = .mentor
                                navigateToLogin = true
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 36)

                    // 회원가입 링크
                    HStack(spacing: 5) {
                        Text("아직 계정이 없으신가요?")
                            .font(.system(size: 14))
                            .foregroundColor(.sonjuSecondary)
                        Button {
                            navigateToSignUp = true
                        } label: {
                            Text("회원가입하기")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.sonjuPrimary)
                        }
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 48)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                    appeared = true
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

// MARK: - 새 역할 카드 (세로형 중앙 정렬)

struct RoleCardNew: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Circle()
                        .fill(color.opacity(0.08))
                        .frame(width: 86, height: 86)
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(color)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.sonjuText)
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.sonjuSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                HStack(spacing: 4) {
                    Text("시작하기")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(color)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(color.opacity(0.1))
                .cornerRadius(20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: color.opacity(0.18), radius: 16, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(color.opacity(isSelected ? 0.7 : 0), lineWidth: 2)
            )
        }
        .buttonStyle(PressButtonStyle())
    }
}

#Preview {
    RoleSelectView()
        .environmentObject(AuthViewModel())
}
