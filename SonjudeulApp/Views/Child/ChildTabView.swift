import SwiftUI

struct ChildTabView: View {
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
                    Label("예약내역", systemImage: "calendar")
                }
                .tag(1)

            ReportListView()
                .tabItem {
                    Label("리포트", systemImage: "doc.richtext.fill")
                }
                .tag(2)

            MyPageView()
                .tabItem {
                    Label("마이", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.sonjuPrimary)
    }
}
