import SwiftUI

struct ChildTabView: View {
    @EnvironmentObject var scheduleStore: ScheduleStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
                .tag(0)

            BookingHistoryView()
                .tabItem {
                    Label("예약내역", systemImage: "list.bullet")
                }
                .tag(1)

            CalendarView()
                .environmentObject(scheduleStore)
                .tabItem {
                    Label("캘린더", systemImage: "calendar")
                }
                .tag(2)

            ReportListView()
                .tabItem {
                    Label("리포트", systemImage: "doc.richtext.fill")
                }
                .tag(3)

            MyPageView()
                .tabItem {
                    Label("마이", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(.sonjuPrimary)
    }
}
