import SwiftUI

#Preview("멘토 홈") {
    MentorHomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(BookingStore())
}

#Preview("멘토 일정") {
    NavigationStack {
        MentorScheduleView()
            .environmentObject(BookingStore())
            .environmentObject(AuthViewModel())
            .environmentObject(ReportViewModel())
            .environmentObject(ReportStore())
    }
}

#Preview("자녀 리뷰") {
    MentorChildReviewsView()
        .environmentObject(AuthViewModel())
        .environmentObject(BookingStore())
}

struct MentorTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var scheduleStore: ScheduleStore
    @StateObject var reportVM = ReportViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MentorHomeView()
                .tabItem { Label("홈", systemImage: "house.fill") }
                .tag(0)

            MentorScheduleView()
                .tabItem { Label("방문 일정", systemImage: "calendar") }
                .tag(1)

            CalendarView()
                .environmentObject(scheduleStore)
                .tabItem { Label("캘린더", systemImage: "calendar.badge.clock") }
                .tag(2)

            MentorChildReviewsView()
                .tabItem { Label("자녀 리뷰", systemImage: "quote.bubble.fill") }
                .tag(3)

            MentorMyPageView()
                .tabItem { Label("마이페이지", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(.sonjuPrimary)
        .environmentObject(reportVM)
    }
}

struct MentorHomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore

    private let feePerVisit = 14_000

    private var myId: UUID? { auth.currentUser?.id }

    private var thisMonthCompleted: [BookingRecord] {
        guard let id = myId else { return [] }
        return bookingStore.completedThisMonth(forMentor: id)
    }
    private var monthlyCount: Int { thisMonthCompleted.count }
    private var monthlyEarnings: String {
        let won = monthlyCount * feePerVisit
        return won == 0 ? "0원" : "\(won.formatted())원"
    }
    private var myTodayBooking: BookingRecord? {
        guard let id = myId else { return nil }
        return bookingStore.todayBooking(forMentor: id)
    }
    private var ratingText: String {
        guard let id = myId else { return "⭐ 5.0" }
        return String(format: "⭐ %.1f", bookingStore.averageRating(forMentor: id))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Personalized greeting banner
                        MentorGreetingBanner(
                            name: auth.currentUser?.name ?? "멘토",
                            ratingText: ratingText
                        )

                        // Today's visit card
                        TodayVisitCard(booking: myTodayBooking)
                            .padding(.horizontal, 24)

                        // Monthly stats
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 0) {
                                // Colored accent bar at top
                                Rectangle()
                                    .fill(Color.sonjuPrimary)
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                    .padding(.bottom, 14)

                                VStack(alignment: .leading, spacing: 14) {
                                    Text("이번 달 현황")
                                        .font(.sonjuHeadline)
                                        .foregroundColor(.sonjuText)

                                    HStack {
                                        StatItem(label: "방문 횟수", value: "\(monthlyCount)회")
                                        Divider().frame(height: 40)
                                        StatItem(label: "예상 수익", value: monthlyEarnings)
                                        Divider().frame(height: 40)
                                        StatItem(label: "평점", value: ratingText)
                                    }

                                    if monthlyCount == 0 {
                                        Divider().background(Color.sonjuDivider)
                                        HStack(spacing: 8) {
                                            Image(systemName: "info.circle")
                                                .foregroundColor(.sonjuSecondary)
                                            Text("이번 달 완료된 방문이 없어요")
                                                .font(.sonjuCaption)
                                                .foregroundColor(.sonjuSecondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Mentor Greeting Banner

struct MentorGreetingBanner: View {
    let name: String
    let ratingText: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF8ED"), Color(hex: "#FFE4B2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(MentorRoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
            .shadow(color: Color.sonjuPrimary.opacity(0.12), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 0) {
                // Top row: title + bell
                HStack {
                    Text("멘토 홈")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.sonjuText)
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

                // Greeting text + rating badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("안녕하세요, \(name)님! 👋")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.sonjuText)
                        Text("오늘도 최고의 멘토가 되어주세요")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                    }
                    Spacer()
                    // Star rating badge
                    Text(ratingText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.sonjuDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.75))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.sonjuPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct MentorRoundedCorner: Shape {
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

struct TodayVisitCard: View {
    let booking: BookingRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘 방문 일정")
                .font(.sonjuHeadline)
                .foregroundColor(.white)

            if let booking = booking {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(booking.date, systemImage: "clock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Label(booking.plan, systemImage: "book.fill")
                            .font(.sonjuCaption)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    Text(booking.status)
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(20)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.6))
                    Text("오늘 예정된 방문이 없어요")
                        .font(.sonjuBody)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.sonjuPrimary, Color.sonjuDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.sonjuPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.sonjuHeadline)
                .foregroundColor(.sonjuText)
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MentorScheduleView: View {
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var reportVM: ReportViewModel
    @EnvironmentObject var reportStore: ReportStore
    @State private var reportBooking: BookingRecord? = nil
    @State private var showCompleteAlert = false
    @State private var pendingId: UUID? = nil
    @State private var profileBooking: BookingRecord? = nil

    // 아직 멘토가 배정 안 된 신규 신청
    private var pendingRequests: [BookingRecord] {
        bookingStore.bookings.filter { $0.status == "멘토 찾는 중" }
    }

    // 내가 수락한 확정 일정
    private var myBookings: [BookingRecord] {
        guard let id = auth.currentUser?.id else { return [] }
        return bookingStore.bookings(forMentor: id)
    }

    private var isEmpty: Bool { pendingRequests.isEmpty && myBookings.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                if isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 52))
                            .foregroundColor(.sonjuPrimary.opacity(0.4))
                        Text("예약 신청이 없어요")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        Text("자녀 회원이 신청하면 이곳에 표시됩니다")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            // 신규 신청 섹션
                            if !pendingRequests.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("신규 신청")
                                            .font(.sonjuHeadline)
                                            .foregroundColor(.sonjuText)
                                        Spacer()
                                        Text("\(pendingRequests.count)건")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(hex: "#FF9800"))
                                            .cornerRadius(20)
                                    }

                                    ForEach(pendingRequests) { booking in
                                        SonjuCard {
                                            VStack(spacing: 10) {
                                                HStack(spacing: 14) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(booking.statusColor.opacity(0.12))
                                                            .frame(width: 44, height: 44)
                                                        Image(systemName: "person.fill.questionmark")
                                                            .foregroundColor(booking.statusColor)
                                                            .font(.system(size: 18))
                                                    }
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text(booking.date)
                                                            .font(.sonjuCaption)
                                                            .foregroundColor(.sonjuSecondary)
                                                        Text(booking.plan)
                                                            .font(.sonjuBody)
                                                            .foregroundColor(.sonjuText)
                                                    }
                                                    Spacer()
                                                    Text("수락 대기")
                                                        .font(.sonjuCaption)
                                                        .foregroundColor(booking.statusColor)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 4)
                                                        .background(booking.statusColor.opacity(0.1))
                                                        .cornerRadius(20)
                                                }
                                                Button {
                                                    profileBooking = booking
                                                } label: {
                                                    Label("신청자 프로필 보기", systemImage: "person.crop.circle.badge.checkmark")
                                                        .font(.sonjuHeadline)
                                                        .foregroundColor(.white)
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 42)
                                                        .background(Color(hex: "#FF9800"))
                                                        .cornerRadius(10)
                                                }
                                                .buttonStyle(PressButtonStyle())
                                            }
                                        }
                                    }
                                }
                            }

                            // 내 확정 일정 섹션
                            if !myBookings.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("내 확정 일정")
                                        .font(.sonjuHeadline)
                                        .foregroundColor(.sonjuText)

                                    ForEach(myBookings) { booking in
                                        SonjuCard {
                                            VStack(spacing: 10) {
                                                HStack(spacing: 14) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(booking.statusColor.opacity(0.12))
                                                            .frame(width: 44, height: 44)
                                                        Image(systemName: booking.status == "예약 확정"
                                                              ? "calendar.badge.checkmark"
                                                              : "checkmark.circle.fill")
                                                            .foregroundColor(booking.statusColor)
                                                            .font(.system(size: 20))
                                                    }
                                                    VStack(alignment: .leading, spacing: 3) {
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
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 4)
                                                        .background(booking.statusColor.opacity(0.1))
                                                        .cornerRadius(20)
                                                }
                                                if booking.status == "예약 확정" {
                                                    Button {
                                                        pendingId = booking.id
                                                        showCompleteAlert = true
                                                    } label: {
                                                        Label("방문 완료", systemImage: "checkmark.circle.fill")
                                                            .font(.sonjuHeadline)
                                                            .foregroundColor(.white)
                                                            .frame(maxWidth: .infinity)
                                                            .frame(height: 42)
                                                            .background(Color.sonjuPrimary)
                                                            .cornerRadius(10)
                                                    }
                                                    .buttonStyle(PressButtonStyle())
                                                } else if booking.status == "방문 완료" {
                                                    if booking.reportWritten {
                                                        HStack(spacing: 6) {
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundColor(.sonjuSuccess)
                                                            Text("리포트 작성 완료")
                                                                .font(.sonjuHeadline)
                                                                .foregroundColor(.sonjuSuccess)
                                                        }
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 42)
                                                        .background(Color.sonjuSuccess.opacity(0.1))
                                                        .cornerRadius(10)
                                                    } else {
                                                        Button {
                                                            reportBooking = booking
                                                        } label: {
                                                            Label("리포트 작성하기", systemImage: "square.and.pencil")
                                                                .font(.sonjuHeadline)
                                                                .foregroundColor(.sonjuPrimary)
                                                                .frame(maxWidth: .infinity)
                                                                .frame(height: 42)
                                                                .background(Color.sonjuPrimary.opacity(0.1))
                                                                .cornerRadius(10)
                                                        }
                                                        .buttonStyle(PressButtonStyle())
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("방문 일정")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $profileBooking) { booking in
                BookingRequesterProfileView(booking: booking)
                    .environmentObject(auth)
                    .environmentObject(bookingStore)
            }
            .alert("방문 완료 처리", isPresented: $showCompleteAlert) {
                Button("취소", role: .cancel) {}
                Button("완료") {
                    if let id = pendingId,
                       let booking = bookingStore.bookings.first(where: { $0.id == id }) {
                        bookingStore.markVisited(id: id)
                        reportBooking = bookingStore.bookings.first(where: { $0.id == id }) ?? booking
                    }
                }
            } message: {
                Text("방문을 완료 처리하면 자녀분께 알림이 전송됩니다.\n계속하시겠어요?")
            }
            .sheet(item: $reportBooking) { booking in
                NavigationStack {
                    ReportWriteView(booking: booking)
                        .environmentObject(reportVM)
                        .environmentObject(reportStore)
                        .environmentObject(bookingStore)
                        .environmentObject(auth)
                }
            }
        }
    }
}

struct MentorMyPageView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @State private var pushEnabled = true
    @State private var showLogoutAlert = false

    private let feePerVisit = 14_000

    private var completedVisits: [BookingRecord] {
        guard let id = auth.currentUser?.id else { return [] }
        return bookingStore.bookings(forMentor: id).filter { $0.status == "방문 완료" }
    }

    private var totalCount: Int { completedVisits.count }
    private var totalEarnings: String {
        let won = totalCount * feePerVisit
        return won == 0 ? "0원" : "\(won.formatted())원"
    }
    private var ratingText: String {
        guard let id = auth.currentUser?.id else { return "⭐ 5.0" }
        return String(format: "⭐ %.1f", bookingStore.averageRating(forMentor: id))
    }

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
                                    Text(auth.currentUser?.name ?? "멘토")
                                        .font(.sonjuTitle)
                                        .foregroundColor(.sonjuText)
                                    Text(auth.currentUser?.university ?? "대학생 멘토")
                                        .font(.sonjuCaption)
                                        .foregroundColor(.sonjuSecondary)
                                    StarRatingView(rating: {
                                        guard let id = auth.currentUser?.id else { return 5.0 }
                                        return bookingStore.averageRating(forMentor: id)
                                    }())
                                }
                                Spacer()
                                VStack(spacing: 8) {
                                    BadgeView(text: "활동중", color: .sonjuSuccess)
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
                        }
                        .padding(.horizontal, 24)

                        // 수익 현황
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "수익 현황")

                                HStack {
                                    StatItem(label: "완료 방문", value: "\(totalCount)회")
                                    Divider().frame(height: 40)
                                    StatItem(label: "누적 수익", value: totalEarnings)
                                    Divider().frame(height: 40)
                                    StatItem(label: "평점", value: ratingText)
                                }

                                if totalCount == 0 {
                                    Divider().background(Color.sonjuDivider)
                                    HStack(spacing: 10) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.sonjuSecondary)
                                        Text("방문을 완료하면 수익이 집계됩니다")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // 자녀 리뷰
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    SectionHeader(title: "자녀 리뷰")
                                    Spacer()
                                    let reviewList: [BookingRecord] = {
                                        guard let id = auth.currentUser?.id else { return [] }
                                        return bookingStore.reviews(forMentor: id)
                                    }()
                                    if !reviewList.isEmpty {
                                        Text("\(reviewList.count)개")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuSecondary)
                                    }
                                }

                                let reviews: [BookingRecord] = {
                                    guard let id = auth.currentUser?.id else { return [] }
                                    return bookingStore.reviews(forMentor: id)
                                }()

                                if reviews.isEmpty {
                                    HStack(spacing: 10) {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .foregroundColor(.sonjuPrimary.opacity(0.4))
                                            .font(.system(size: 24))
                                        Text("아직 받은 리뷰가 없어요")
                                            .font(.sonjuBody)
                                            .foregroundColor(.sonjuSecondary)
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(reviews) { review in
                                            MentorReviewRow(review: review)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // 최근 방문 이력
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "최근 방문 이력")
                                if completedVisits.isEmpty {
                                    HStack(spacing: 12) {
                                        Image(systemName: "house.and.flag")
                                            .font(.system(size: 28))
                                            .foregroundColor(.sonjuPrimary.opacity(0.5))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("아직 방문 완료 이력이 없어요")
                                                .font(.sonjuBody)
                                                .foregroundColor(.sonjuText)
                                            Text("방문 완료 처리 후 이곳에 쌓여요")
                                                .font(.sonjuCaption)
                                                .foregroundColor(.sonjuSecondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    VStack(spacing: 0) {
                                        ForEach(completedVisits.prefix(3)) { visit in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(visit.date)
                                                        .font(.sonjuCaption)
                                                        .foregroundColor(.sonjuSecondary)
                                                    Text(visit.plan)
                                                        .font(.sonjuBody)
                                                        .foregroundColor(.sonjuText)
                                                }
                                                Spacer()
                                                Text("방문 완료")
                                                    .font(.sonjuCaption)
                                                    .foregroundColor(visit.statusColor)
                                            }
                                            .padding(.vertical, 12)
                                            if visit.id != completedVisits.prefix(3).last?.id {
                                                Divider().background(Color.sonjuDivider)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // 설정
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
                                    ColoredMentorSettingsRow(
                                        title: "개인정보 처리방침",
                                        icon: "lock.shield.fill",
                                        iconBg: Color(hex: "#E3F0FF"),
                                        iconColor: Color(hex: "#2196F3")
                                    )
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.sonjuDivider)
                                NavigationLink(destination: TermsOfServiceView()) {
                                    ColoredMentorSettingsRow(
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

// MARK: - Mentor MyPage Gradient Header

private struct MentorMyPageGradientHeader: View {
    let auth: AuthViewModel
    let bookingStore: BookingStore

    private var avgRating: Double {
        guard let id = auth.currentUser?.id else { return 5.0 }
        return bookingStore.averageRating(forMentor: id)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.sonjuPrimary, Color.sonjuDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(MentorMyPageRoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
            .shadow(color: Color.sonjuDeep.opacity(0.35), radius: 10, x: 0, y: 6)
            .frame(height: 240)

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

                // Name, university, star rating
                VStack(spacing: 4) {
                    Text(auth.currentUser?.name ?? "멘토")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(auth.currentUser?.university ?? "대학생 멘토")
                        .font(.sonjuCaption)
                        .foregroundColor(.white.opacity(0.8))
                    StarRatingView(rating: avgRating)
                        .colorScheme(.dark)
                }

                // Active badge + Edit button
                HStack(spacing: 10) {
                    BadgeView(text: "활동중", color: .sonjuSuccess)
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
            }
            .padding(.bottom, 18)
        }
        .frame(height: 240)
        .ignoresSafeArea(edges: .top)
    }
}

struct MentorMyPageRoundedCorner: Shape {
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

struct MentorChildReviewsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore

    private var reviews: [BookingRecord] {
        guard let id = auth.currentUser?.id else { return [] }
        return bookingStore.reviews(forMentor: id)
    }

    private var avgRating: Double {
        guard let id = auth.currentUser?.id else { return 5.0 }
        return bookingStore.averageRating(forMentor: id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                if reviews.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.bubble")
                            .font(.system(size: 52))
                            .foregroundColor(.sonjuPrimary.opacity(0.4))
                        Text("아직 받은 리뷰가 없어요")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        Text("방문 완료 후 자녀가 평가하면\n이곳에 표시돼요")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // 평점 요약 카드
                            SonjuCard {
                                HStack(spacing: 0) {
                                    VStack(spacing: 6) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(Color(hex: "#FFB300"))
                                            Text(String(format: "%.1f", avgRating))
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(.sonjuText)
                                        }
                                        Text("평균 평점")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuSecondary)
                                    }
                                    .frame(maxWidth: .infinity)

                                    Divider().frame(height: 50).background(Color.sonjuDivider)

                                    VStack(spacing: 6) {
                                        Text("\(reviews.count)")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.sonjuText)
                                        Text("총 리뷰")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.vertical, 8)
                            }

                            // 별점 분포
                            SonjuCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "별점 분포")
                                    VStack(spacing: 8) {
                                        ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                                            let count = reviews.filter { ($0.rating ?? 0) == star }.count
                                            let ratio = reviews.isEmpty ? 0.0 : Double(count) / Double(reviews.count)
                                            HStack(spacing: 10) {
                                                HStack(spacing: 2) {
                                                    Text("\(star)")
                                                        .font(.sonjuCaption)
                                                        .foregroundColor(.sonjuSecondary)
                                                        .frame(width: 10)
                                                    Image(systemName: "star.fill")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(Color(hex: "#FFB300"))
                                                }
                                                GeometryReader { geo in
                                                    ZStack(alignment: .leading) {
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .fill(Color.sonjuDivider)
                                                            .frame(height: 8)
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .fill(Color(hex: "#FFB300"))
                                                            .frame(width: geo.size.width * ratio, height: 8)
                                                    }
                                                }
                                                .frame(height: 8)
                                                Text("\(count)")
                                                    .font(.sonjuCaption)
                                                    .foregroundColor(.sonjuSecondary)
                                                    .frame(width: 16)
                                            }
                                        }
                                    }
                                }
                            }

                            // 리뷰 목록
                            SonjuCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    SectionHeader(title: "전체 리뷰")
                                    VStack(spacing: 12) {
                                        ForEach(reviews) { review in
                                            MentorReviewRow(review: review)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("자녀 리뷰")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MentorReviewRow: View {
    let review: BookingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= (review.rating ?? 0) ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(star <= (review.rating ?? 0) ? Color(hex: "#FFB300") : Color.sonjuDivider)
                }
                Spacer()
                Text(review.date)
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuSecondary)
            }
            if !review.reviewComment.isEmpty {
                Text(review.reviewComment)
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuText)
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .background(Color.sonjuBackground)
        .cornerRadius(12)
    }
}

struct MentorSettingsRow: View {
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

struct ColoredMentorSettingsRow: View {
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
