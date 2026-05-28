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

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile card
                        SonjuCard {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.sonjuPrimary.opacity(0.2))
                                        .frame(width: 64, height: 64)
                                    if let data = auth.currentUser?.profileImageData,
                                       let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 64, height: 64)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                            .foregroundColor(.sonjuPrimary)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(auth.currentUser?.name ?? "")
                                        .font(.sonjuTitle)
                                        .foregroundColor(.sonjuText)
                                    Text("010-****-\(String((auth.currentUser?.phone ?? "0000").suffix(4)))")
                                        .font(.sonjuBody)
                                        .foregroundColor(.sonjuSecondary)
                                }
                                Spacer()
                                if let user = auth.currentUser {
                                    NavigationLink(destination: ProfileEditView(user: user)) {
                                        Text("수정")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
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
                                    Label("푸시 알림 설정", systemImage: "bell.fill")
                                        .font(.sonjuBody)
                                        .foregroundColor(.sonjuText)
                                }
                                .tint(.sonjuPrimary)
                                .padding(.vertical, 12)

                                Divider().background(Color.sonjuDivider)

                                NavigationLink(destination: PrivacyConsentView()) {
                                    SettingsRow(title: "개인정보 처리방침")
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.sonjuDivider)
                                NavigationLink(destination: TermsOfServiceView()) {
                                    SettingsRow(title: "서비스 이용약관")
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.sonjuDivider)

                                Button {
                                    showLogoutAlert = true
                                } label: {
                                    HStack {
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
