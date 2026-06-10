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

    var body: some View {
        Group {
            if !auth.hasCompletedOnboarding {
                OnboardingView()
            } else if !auth.isLoggedIn {
                RoleSelectView()
            } else {
                if auth.selectedRole == .mentor {
                    MentorTabView()
                } else {
                    ChildTabView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: auth.isLoggedIn)
    }
}
