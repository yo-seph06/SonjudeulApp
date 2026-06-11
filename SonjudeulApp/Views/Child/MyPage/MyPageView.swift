import SwiftUI

struct MyPageView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @State private var pushEnabled = true
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 프로필 카드
                        SonjuCard {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.sonjuPrimary.opacity(0.15))
                                        .frame(width: 64, height: 64)
                                    Circle()
                                        .stroke(Color.sonjuPrimary.opacity(0.3), lineWidth: 2)
                                        .frame(width: 64, height: 64)
                                    if let data = auth.currentUser?.profileImageData,
                                       let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 26, height: 26)
                                            .foregroundColor(.sonjuPrimary)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(auth.currentUser?.name ?? "")
                                        .font(.sonjuTitle)
                                        .foregroundColor(.sonjuText)
                                    Text("010-****-\(String((auth.currentUser?.phone ?? "0000").suffix(4)))")
                                        .font(.sonjuCaption)
                                        .foregroundColor(.sonjuSecondary)
                                }
                                Spacer()
                                if let user = auth.currentUser {
                                    NavigationLink(destination: ProfileEditView(user: user)) {
                                        Text("수정")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuPrimary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(Color.sonjuPrimary.opacity(0.1))
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Subscription
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "구독 현황")
                                if bookingStore.bookings.isEmpty {
                                    HStack(spacing: 12) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 28))
                                            .foregroundColor(.sonjuPrimary.opacity(0.5))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("아직 구독 내역이 없어요")
                                                .font(.sonjuBody)
                                                .foregroundColor(.sonjuText)
                                            Text("첫 예약을 완료하면 이곳에 표시돼요")
                                                .font(.sonjuCaption)
                                                .foregroundColor(.sonjuSecondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    BadgeView(text: bookingStore.bookings.first?.plan ?? "안심 정기구독")
                                    HStack {
                                        Label("총 방문 횟수: \(bookingStore.bookings.count)회", systemImage: "house.fill")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuSecondary)
                                        Spacer()
                                        Button("구독 관리") {}
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuPrimary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Visit history
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "최근 방문 이력")
                                if bookingStore.bookings.isEmpty {
                                    HStack(spacing: 12) {
                                        Image(systemName: "house.and.flag")
                                            .font(.system(size: 28))
                                            .foregroundColor(.sonjuPrimary.opacity(0.5))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("아직 방문 이력이 없어요")
                                                .font(.sonjuBody)
                                                .foregroundColor(.sonjuText)
                                            Text("예약 후 수업이 완료되면 쌓여요")
                                                .font(.sonjuCaption)
                                                .foregroundColor(.sonjuSecondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    VStack(spacing: 0) {
                                        ForEach(bookingStore.bookings.prefix(3)) { booking in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(booking.date)
                                                        .font(.sonjuCaption)
                                                        .foregroundColor(.sonjuSecondary)
                                                    Text(booking.plan)
                                                        .font(.sonjuBody)
                                                        .foregroundColor(.sonjuText)
                                                }
                                                Spacer()
                                                Text(booking.status)
                                                    .font(.sonjuCaption)
                                                    .foregroundColor(booking.statusColor)
                                            }
                                            .padding(.vertical, 12)
                                            if booking.id != bookingStore.bookings.prefix(3).last?.id {
                                                Divider().background(Color.sonjuDivider)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Settings
                        SonjuCard {
                            VStack(spacing: 0) {
                                Toggle(isOn: $pushEnabled) {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.sonjuPrimary.opacity(0.15))
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "bell.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.sonjuPrimary)
                                        }
                                        Text("푸시 알림 설정")
                                            .font(.sonjuBody)
                                            .foregroundColor(.sonjuText)
                                    }
                                }
                                .tint(.sonjuPrimary)
                                .padding(.vertical, 12)

                                Divider().background(Color.sonjuDivider)

                                NavigationLink(destination: PrivacyConsentView()) {
                                    ColoredSettingsRow(
                                        title: "개인정보 처리방침",
                                        icon: "lock.shield.fill",
                                        iconBg: Color(hex: "#E3F0FF"),
                                        iconColor: Color(hex: "#2196F3")
                                    )
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.sonjuDivider)
                                NavigationLink(destination: TermsOfServiceView()) {
                                    ColoredSettingsRow(
                                        title: "서비스 이용약관",
                                        icon: "doc.text.fill",
                                        iconBg: Color(hex: "#F3E8FF"),
                                        iconColor: Color(hex: "#9C27B0")
                                    )
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.sonjuDivider)

                                Button {
                                    showLogoutAlert = true
                                } label: {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.red.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.red)
                                        }
                                        Text("로그아웃")
                                            .font(.sonjuBody)
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                }

                                Divider().background(Color.sonjuDivider)

                                HStack {
                                    Text("앱 버전")
                                        .font(.sonjuBody)
                                        .foregroundColor(.sonjuSecondary)
                                    Spacer()
                                    Text("1.0.0")
                                        .font(.sonjuCaption)
                                        .foregroundColor(.sonjuSecondary)
                                }
                                .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.large)
            .alert("로그아웃", isPresented: $showLogoutAlert) {
                Button("취소", role: .cancel) {}
                Button("로그아웃", role: .destructive) {
                    auth.logout()
                }
            } message: {
                Text("정말 로그아웃 하시겠어요?")
            }
        }
    }
}

// MARK: - Gradient Header

private struct MyPageGradientHeader: View {
    let auth: AuthViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.sonjuPrimary, Color.sonjuDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(MyPageRoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
            .shadow(color: Color.sonjuDeep.opacity(0.35), radius: 10, x: 0, y: 6)
            .frame(height: 200)

            VStack(spacing: 10) {
                // Profile photo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 86, height: 86)
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 86, height: 86)
                    if let data = auth.currentUser?.profileImageData,
                       let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                // Name & phone
                VStack(spacing: 3) {
                    Text(auth.currentUser?.name ?? "사용자")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("010-****-\(String((auth.currentUser?.phone ?? "0000").suffix(4)))")
                        .font(.sonjuCaption)
                        .foregroundColor(.white.opacity(0.8))
                }

                // Edit button
                if let user = auth.currentUser {
                    NavigationLink(destination: ProfileEditView(user: user)) {
                        Text("수정")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 18)
        }
        .frame(height: 200)
        .ignoresSafeArea(edges: .top)
    }
}

struct MyPageRoundedCorner: Shape {
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

#Preview {
    MyPageView()
        .environmentObject(AuthViewModel())
        .environmentObject(BookingStore())
}

// MARK: - Colored Settings Row

struct ColoredSettingsRow: View {
    let title: String
    let icon: String
    let iconBg: Color
    let iconColor: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBg)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.sonjuSecondary)
                .font(.system(size: 12))
        }
        .padding(.vertical, 12)
    }
}

struct SettingsRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.sonjuSecondary)
                .font(.system(size: 12))
        }
        .padding(.vertical, 12)
    }
}
