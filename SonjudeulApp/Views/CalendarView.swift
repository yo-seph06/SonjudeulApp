import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var deviceCalendar: DeviceCalendarStore
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var showAddSheet = false
    @State private var showDeviceCalendarSheet = false

    private let cal = Calendar.current
    private let weekDays = ["일", "월", "화", "수", "목", "금", "토"]

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: currentMonth) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        var day = interval.start
        while day < interval.end {
            days.append(day)
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return days
    }

    private var myBookings: [BookingRecord] {
        guard let id = auth.currentUser?.id else { return [] }
        if auth.selectedRole == .mentor {
            return bookingStore.bookings(forMentor: id)
        } else {
            return bookingStore.bookings(forChild: id)
        }
    }

    private func bookingsOn(_ date: Date) -> [BookingRecord] {
        myBookings.filter { cal.isDate($0.rawDate, inSameDayAs: date) }
    }

    /// 기기 캘린더 일정 중 손주들에서 내보낸 내 일정은 손주들 일정으로만 한 번 표시한다
    private var ownScheduleIds: Set<UUID> {
        Set(scheduleStore.events(forOwner: auth.currentUser?.id).map(\.id))
    }

    private func deviceEventsOn(_ date: Date) -> [DeviceCalendarEvent] {
        deviceCalendar.events(on: date, ownerId: auth.currentUser?.id, excluding: ownScheduleIds)
    }

    private func dotCount(for date: Date) -> Int {
        let total = bookingsOn(date).count + scheduleStore.eventsOn(date, ownerId: auth.currentUser?.id).count
            + deviceEventsOn(date).count
        return min(total, 3)
    }

    private var upcomingBookings: [BookingRecord] {
        myBookings
            .filter { $0.rawDate > Date() && $0.status != "방문 완료" }
            .sorted { $0.rawDate < $1.rawDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // 월 네비게이션
                        HStack {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    currentMonth = cal.date(byAdding: .month, value: -1, to: currentMonth)!
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.sonjuPrimary)
                                    .frame(width: 44, height: 44)
                            }
                            Spacer()
                            Text(monthTitle)
                                .font(.sonjuTitle)
                                .foregroundColor(.sonjuText)
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    currentMonth = cal.date(byAdding: .month, value: 1, to: currentMonth)!
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.sonjuPrimary)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal, 24)

                        // 달력 그리드
                        SonjuCard {
                            VStack(spacing: 4) {
                                HStack(spacing: 0) {
                                    ForEach(Array(weekDays.enumerated()), id: \.offset) { i, day in
                                        Text(day)
                                            .font(.sonjuCaption)
                                            .foregroundColor(i == 0 ? .red : (i == 6 ? Color(hex: "#1565C0") : .sonjuSecondary))
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.bottom, 4)

                                Divider().background(Color.sonjuDivider)

                                let days = daysInMonth
                                let rows = Int(ceil(Double(days.count) / 7.0))
                                ForEach(0..<rows, id: \.self) { row in
                                    HStack(spacing: 0) {
                                        ForEach(0..<7, id: \.self) { col in
                                            let idx = row * 7 + col
                                            if idx < days.count, let date = days[idx] {
                                                CalDayCell(
                                                    date: date,
                                                    isSelected: selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false,
                                                    isToday: cal.isDateInToday(date),
                                                    dotCount: dotCount(for: date),
                                                    weekday: col
                                                ) { selectedDate = (selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false) ? nil : date }
                                            } else {
                                                Color.clear.frame(maxWidth: .infinity, minHeight: 52)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        DeviceCalendarStatusRow { showDeviceCalendarSheet = true }
                            .padding(.horizontal, 24)

                        // 선택된 날짜 항목
                        if let selected = selectedDate {
                            let dayBookings = bookingsOn(selected)
                            let dayEvents = scheduleStore.eventsOn(selected, ownerId: auth.currentUser?.id)
                            let dayDeviceEvents = deviceEventsOn(selected)

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(formatDate(selected))
                                        .font(.sonjuHeadline)
                                        .foregroundColor(.sonjuText)
                                    Spacer()
                                    Button {
                                        showAddSheet = true
                                    } label: {
                                        Label("일정 추가", systemImage: "plus.circle.fill")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuPrimary)
                                    }
                                }
                                .padding(.horizontal, 24)

                                if dayBookings.isEmpty && dayEvents.isEmpty && dayDeviceEvents.isEmpty {
                                    SonjuCard {
                                        HStack(spacing: 12) {
                                            Image(systemName: "calendar.badge.exclamationmark")
                                                .font(.system(size: 26))
                                                .foregroundColor(.sonjuPrimary.opacity(0.4))
                                            Text("이 날 일정이 없어요")
                                                .font(.sonjuBody)
                                                .foregroundColor(.sonjuSecondary)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                } else {
                                    ForEach(dayBookings) { booking in
                                        CalBookingCard(booking: booking)
                                            .padding(.horizontal, 24)
                                    }
                                    ForEach(dayEvents) { event in
                                        ScheduleEventCard(event: event)
                                            .padding(.horizontal, 24)
                                    }
                                    ForEach(dayDeviceEvents) { event in
                                        DeviceEventCard(event: event, day: selected)
                                            .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }

                        // 다가오는 예약
                        if !upcomingBookings.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("다가오는 예약")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuText)
                                    .padding(.horizontal, 24)

                                ForEach(upcomingBookings.prefix(5)) { booking in
                                    CalBookingCard(booking: booking)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }

                        // 다가오는 내 일정
                        let upcoming = scheduleStore.upcomingEvents(ownerId: auth.currentUser?.id)
                        if !upcoming.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("다가오는 일정")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuText)
                                    .padding(.horizontal, 24)

                                ForEach(upcoming.prefix(5)) { event in
                                    ScheduleEventCard(event: event)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("캘린더")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.sonjuPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                ScheduleAddView(initialDate: selectedDate ?? Date())
                    .environmentObject(scheduleStore)
                    .environmentObject(auth)
                    .environmentObject(deviceCalendar)
            }
            .sheet(isPresented: $showDeviceCalendarSheet) {
                DeviceCalendarSettingsView()
                    .environmentObject(deviceCalendar)
            }
            .onAppear { deviceCalendar.load(around: currentMonth) }
            .onChange(of: currentMonth) { _, month in deviceCalendar.load(around: month) }
            .refreshable { deviceCalendar.refreshFromSystem() }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: date)
    }
}

// MARK: - 날짜 셀

struct CalDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let dotCount: Int
    let weekday: Int
    let action: () -> Void

    private var dayText: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private var textColor: Color {
        if isSelected { return .white }
        if weekday == 0 { return .red }
        if weekday == 6 { return Color(hex: "#1565C0") }
        return .sonjuText
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Circle().fill(Color.sonjuPrimary).frame(width: 34, height: 34)
                    } else if isToday {
                        Circle().strokeBorder(Color.sonjuPrimary, lineWidth: 2).frame(width: 34, height: 34)
                    }
                    Text(dayText)
                        .font(.system(size: 15, weight: isToday ? .bold : .regular))
                        .foregroundColor(isSelected ? .white : textColor)
                }

                HStack(spacing: 3) {
                    ForEach(0..<dotCount, id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? Color.white : Color.sonjuPrimary)
                            .frame(width: 5, height: 5)
                    }
                    if dotCount == 0 { Color.clear.frame(width: 5, height: 5) }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 예약 카드

struct CalBookingCard: View {
    let booking: BookingRecord

    private var icon: String {
        switch booking.status {
        case "예약 확정":    return "calendar.badge.checkmark"
        case "멘토 찾는 중": return "magnifyingglass.circle.fill"
        case "방문 완료":    return "checkmark.circle.fill"
        default:            return "calendar"
        }
    }

    var body: some View {
        SonjuCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(booking.statusColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .foregroundColor(booking.statusColor)
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.plan)
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuText)
                    Text(booking.date)
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                    if !booking.mentorName.isEmpty {
                        Label(booking.mentorName, systemImage: "person.fill")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                    }
                }
                Spacer()
                Text(booking.status)
                    .font(.sonjuCaption)
                    .foregroundColor(booking.statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(booking.statusColor.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }
}

// MARK: - 기기 캘린더 연동 상태

struct DeviceCalendarStatusRow: View {
    @EnvironmentObject var deviceCalendar: DeviceCalendarStore
    let action: () -> Void

    private var text: String {
        if let error = deviceCalendar.lastError, deviceCalendar.isEnabled { return error }
        return deviceCalendar.isEnabled ? "휴대전화 캘린더 일정도 함께 보고 있어요" : "휴대전화 캘린더 일정도 함께 보기"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: deviceCalendar.isEnabled ? "iphone.gen3.badge.checkmark" : "iphone.gen3")
                    .foregroundColor(deviceCalendar.lastError != nil && deviceCalendar.isEnabled ? .orange : .sonjuPrimary)
                Text(text)
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuSecondary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sonjuSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.sonjuCard)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 기기 캘린더 일정 카드 (읽기 전용)

struct DeviceEventCard: View {
    let event: DeviceCalendarEvent
    let day: Date

    private var timeText: String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        if event.isAllDay { return "종일" }
        f.dateFormat = "a h:mm"
        let sameDay = cal.isDate(event.start, inSameDayAs: event.end)
        if sameDay { return "\(f.string(from: event.start)) ~ \(f.string(from: event.end))" }
        // 여러 날에 걸친 일정은 날짜까지 표시
        f.dateFormat = "M/d a h:mm"
        return "\(f.string(from: event.start)) ~ \(f.string(from: event.end))"
    }

    var body: some View {
        SonjuCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.sonjuSecondary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "iphone.gen3")
                        .foregroundColor(.sonjuSecondary)
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuText)
                    Text(timeText)
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                    if let location = event.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(event.calendarTitle)
                        .font(.system(size: 11))
                        .foregroundColor(.sonjuSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.sonjuSecondary.opacity(0.1))
                        .cornerRadius(20)
                        .lineLimit(1)
                    if event.isRecurring {
                        Image(systemName: "repeat")
                            .font(.system(size: 11))
                            .foregroundColor(.sonjuSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - 기기 캘린더 연동 설정

struct DeviceCalendarSettingsView: View {
    @EnvironmentObject var deviceCalendar: DeviceCalendarStore
    @Environment(\.dismiss) private var dismiss
    @State private var requesting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("휴대전화 캘린더 연동", systemImage: "calendar")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuText)
                                bullet("휴대전화 캘린더 앱의 일정을 손주들 캘린더에 함께 보여드려요.")
                                bullet("손주들에서 일정을 만들 때 휴대전화 캘린더에도 추가할 수 있어요.")
                                bullet("불러온 일정은 이 기기 화면에만 표시되고, 손주들에 저장되거나 다른 회원(자녀·멘토)에게 공유되지 않아요.")
                                bullet("연동은 지금 로그인한 계정에서만 켜져요. 다른 계정으로 로그인하면 보이지 않아요.")
                            }
                        }

                        statusSection

                        if let error = deviceCalendar.lastError {
                            Text(error)
                                .font(.sonjuCaption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("캘린더 연동")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.sonjuPrimary)
                }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if deviceCalendar.isEnabled && deviceCalendar.access == .granted {
            VStack(spacing: 12) {
                Text("연동 중이에요")
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuSuccess)
                    .frame(maxWidth: .infinity)
                AmberButton(title: "지금 새로고침") { deviceCalendar.refreshFromSystem() }
                Button("연동 끄기") { deviceCalendar.disable() }
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuSecondary)
                    .frame(maxWidth: .infinity)
            }
        } else {
            switch deviceCalendar.access {
            case .denied, .writeOnly:
                VStack(alignment: .leading, spacing: 12) {
                    Text(deviceCalendar.access == .writeOnly
                         ? "현재 '일정 추가만' 허용되어 있어 일정을 불러올 수 없어요. 설정에서 '전체 접근'으로 바꿔주세요."
                         : "캘린더 접근이 허용되지 않았어요. 연동하지 않아도 손주들 캘린더는 그대로 사용할 수 있어요.")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                    AmberButton(title: "설정에서 허용하기") { deviceCalendar.openSystemSettings() }
                }
            default:
                AmberButton(title: requesting ? "요청 중…" : "연동하기", disabled: requesting) {
                    requesting = true
                    Task {
                        await deviceCalendar.enable()
                        requesting = false
                    }
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundColor(.sonjuPrimary)
            Text(text)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(BookingStore())
        .environmentObject(AuthViewModel())
        .environmentObject(ScheduleStore())
        .environmentObject(DeviceCalendarStore())
}
