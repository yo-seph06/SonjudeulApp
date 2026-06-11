import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @State private var navigateToBooking = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 상단 로고 바
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.sonjuPrimary)
                                .font(.system(size: 20))
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
                                    label: "스마트폰\n활용 교육",
                                    iconBg: Color(hex: "#FFF3E0"),
                                    iconColor: Color.sonjuPrimary
                                )
                                HomeFeatureItem(
                                    icon: "gearshape.2.fill",
                                    label: "기기 최적화\n(스팸/광고 제거)",
                                    iconBg: Color(hex: "#E3F0FF"),
                                    iconColor: Color(hex: "#2196F3")
                                )
                                HomeFeatureItem(
                                    icon: "doc.text.fill",
                                    label: "안부 확인\n리포트 발송",
                                    iconBg: Color(hex: "#E8F5E9"),
                                    iconColor: Color.sonjuSuccess
                                )
                            }
                            .padding(.horizontal, 8)

                            AmberButton(title: "서비스 신청하기") {
                                navigateToBooking = true
                            }
                            .padding(.horizontal, 24)
                            .shadow(color: Color.sonjuPrimary.opacity(0.35), radius: 10, x: 0, y: 4)
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

// MARK: - Greeting Banner

struct HomeGreetingBanner: View {
    let name: String
    let nextBooking: BookingRecord?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Color(hex: "#FFF8ED"), Color(hex: "#FFE4B2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(HomeRoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
            .shadow(color: Color.sonjuPrimary.opacity(0.12), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 0) {
                // Top row: logo + bell
                HStack {
                    HStack(spacing: 8) {
                        Image("SonjudeulLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        Text("손주들")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.sonjuText)
                    }
                    Spacer()
                    Button {} label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 38, height: 38)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.sonjuDeep)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)

                // Greeting text
                VStack(alignment: .leading, spacing: 4) {
                    if name.isEmpty {
                        Text("안녕하세요! 👋")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.sonjuText)
                    } else {
                        Text("안녕하세요, \(name)님! 👋")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.sonjuText)
                    }
                    Text("오늘도 부모님께 효도하는 하루 되세요")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, nextBooking != nil ? 12 : 20)

                // Next booking pill (if exists)
                if let booking = nextBooking {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.sonjuDeep)
                        Text("다음 방문")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.sonjuDeep)
                        Rectangle()
                            .fill(Color.sonjuDeep.opacity(0.25))
                            .frame(width: 1, height: 12)
                        Text(booking.date)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.sonjuText)
                        Text("·")
                            .foregroundColor(.sonjuSecondary)
                            .font(.system(size: 11))
                        Text(booking.plan)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.sonjuText)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.sonjuPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct HomeRoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
                    colors: [Color(hex: "#FFF3E0"), Color(hex: "#FFD9A0"), Color(hex: "#FFB74D").opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 240)
                .shadow(color: Color.sonjuPrimary.opacity(0.18), radius: 14, x: 0, y: 6)

            // Floating decorations
            VStack {
                HStack {
                    Image(systemName: "sparkle")
                        .foregroundColor(Color(hex: "#FFB300").opacity(0.55))
                        .font(.system(size: 16))
                        .offset(x: 20, y: 18)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(.sonjuPrimary.opacity(0.5))
                        .font(.system(size: 24))
                        .offset(x: -20, y: 22)
                }
                Spacer()
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.sonjuPrimary.opacity(0.3))
                        .font(.system(size: 14))
                        .offset(x: 28, y: -24)
                    Spacer()
                    Image(systemName: "sparkle")
                        .foregroundColor(Color(hex: "#FFB300").opacity(0.4))
                        .font(.system(size: 12))
                        .offset(x: -36, y: -16)
                }
            }

            // Extra floating heart top-left
            VStack {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.sonjuDeep.opacity(0.2))
                        .font(.system(size: 10))
                        .offset(x: 52, y: 44)
                    Spacer()
                }
                Spacer()
            }

            HStack(spacing: 24) {
                // Young woman (mentor)
                VStack(spacing: 0) {
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
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.sonjuPrimary, Color.sonjuDeep],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
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

                // Elderly woman (parent)
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
    var iconBg: Color = Color.sonjuPrimary.opacity(0.13)
    var iconColor: Color = Color.sonjuPrimary

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconBg)
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(iconColor)
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
