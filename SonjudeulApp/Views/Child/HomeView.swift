import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var navigateToBooking = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        HStack(spacing: 8) {
                            Image("SonjudeulLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 34, height: 34)
                            Text("손주들")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.sonjuText)
                        }
                        Spacer()
                        Button {} label: {
                            Image(systemName: "bell")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.sonjuText)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            // Hero text
                            VStack(alignment: .leading, spacing: 6) {
                                Text("부모님께")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.sonjuText)

                                (Text("효도를 ").foregroundColor(.sonjuPrimary)
                                 + Text("선물하세요").foregroundColor(.sonjuText))
                                    .font(.system(size: 34, weight: .bold))

                                Text("대학생 멘토가 집으로 찾아가\n디지털 교육과 안부 확인까지!")
                                    .font(.sonjuBody)
                                    .foregroundColor(.sonjuSecondary)
                                    .lineSpacing(5)
                                    .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)

                            // Illustration card
                            HomeIllustrationCard()
                                .padding(.horizontal, 24)

                            // Feature icons
                            HStack(spacing: 0) {
                                HomeFeatureItem(
                                    icon: "iphone.gen2",
                                    label: "스마트폰\n활용 교육"
                                )
                                HomeFeatureItem(
                                    icon: "gearshape.2.fill",
                                    label: "기기 최적화\n(스팸/광고 제거)"
                                )
                                HomeFeatureItem(
                                    icon: "doc.text.fill",
                                    label: "안부 확인\n리포트 발송"
                                )
                            }
                            .padding(.horizontal, 8)

                            AmberButton(title: "서비스 신청하기") {
                                navigateToBooking = true
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToBooking) {
                BookingFlowView()
            }
        }
    }
}

// MARK: — Illustration

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(BookingStore())
}

struct HomeIllustrationCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color(hex: "#FFF3E0"), Color(hex: "#FFE0B2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 200)

            // Floating hearts
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(.sonjuPrimary.opacity(0.45))
                        .font(.system(size: 22))
                        .offset(x: -24, y: 20)
                }
                Spacer()
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.sonjuPrimary.opacity(0.3))
                        .font(.system(size: 14))
                        .offset(x: 28, y: -20)
                    Spacer()
                }
            }

            HStack(spacing: 24) {
                // Young woman
                VStack(spacing: 0) {
                    // Head
                    Circle()
                        .fill(Color(hex: "#FFDAAA"))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24)
                                .foregroundColor(Color(hex: "#C87941"))
                                .offset(y: 6)
                        )
                    // Body
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.sonjuPrimary)
                        .frame(width: 46, height: 64)
                }

                // Phone device
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#3D3D3D"))
                        .frame(width: 36, height: 62)
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: "#E8F5E9"))
                        .frame(width: 28, height: 50)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.sonjuSuccess)
                        .font(.system(size: 16))
                }

                // Elderly woman
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color(hex: "#FFE0CC"))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22)
                                .foregroundColor(Color(hex: "#B86020"))
                                .offset(y: 6)
                        )
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#D4A664"))
                        .frame(width: 42, height: 60)
                }
            }
        }
    }
}

// MARK: — Feature Icon Item

struct HomeFeatureItem: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.sonjuPrimary.opacity(0.13))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.sonjuPrimary)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.sonjuSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
