import SwiftUI
import UserNotifications

@main
struct SonjudeulApp: App {
    @StateObject var auth = AuthViewModel()
    @StateObject var bookingStore = BookingStore()
    @StateObject var reportStore = ReportStore()
    @StateObject var scheduleStore = ScheduleStore()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(auth)
                    .environmentObject(bookingStore)
                    .environmentObject(reportStore)
                    .environmentObject(scheduleStore)
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
                #if DEBUG
                Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
                #endif
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var scheduleStore: ScheduleStore

    var body: some View {
        Group {
            if !auth.hasCompletedOnboarding {
                OnboardingView()
            } else if !auth.isLoggedIn {
                RoleSelectView()
            } else {
                if auth.isAdmin {
                    AdminRootView()
                } else if auth.selectedRole == .mentor {
                    MentorTabView()
                } else {
                    ChildTabView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: auth.isLoggedIn)
        .onAppear { syncNotifications(for: auth.currentUser?.id) }
        .onChange(of: auth.currentUser?.id) { syncNotifications(for: $0) }
    }

    /// 로그인한 회원이 바뀌면 이전 회원의 예약 알림을 지우고 현재 회원의 알림만 다시 등록한다.
    private func syncNotifications(for userId: UUID?) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        guard let userId else { return }
        bookingStore.rescheduleNotifications(for: userId)
        scheduleStore.rescheduleNotifications(for: userId)
    }
}
