import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var auth: AuthViewModel
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil

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
            return bookingStore.bookings.filter { $0.childId == id }
        }
    }

    private func bookingsOn(_ date: Date) -> [BookingRecord] {
        myBookings.filter { cal.isDate($0.rawDate, inSameDayAs: date) }
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
                                // 요일 헤더
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

                                // 날짜 그리드
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
                                                    dotCount: min(bookingsOn(date).count, 3),
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

                        // 선택된 날짜 예약
                        if let selected = selectedDate {
                            let bookings = bookingsOn(selected)
                            VStack(alignment: .leading, spacing: 10) {
                                Text(formatDate(selected))
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuText)
                                    .padding(.horizontal, 24)

                                if bookings.isEmpty {
                                    SonjuCard {
                                        HStack(spacing: 12) {
                                            Image(systemName: "calendar.badge.exclamationmark")
                                                .font(.system(size: 26))
                                                .foregroundColor(.sonjuPrimary.opacity(0.4))
                                            Text("이 날 예약이 없어요")
                                                .font(.sonjuBody)
                                                .foregroundColor(.sonjuSecondary)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                } else {
                                    ForEach(bookings) { booking in
                                        CalBookingCard(booking: booking)
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

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("캘린더")
            .navigationBarTitleDisplayMode(.large)
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

                // 예약 점
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

#Preview {
    CalendarView()
        .environmentObject(BookingStore())
        .environmentObject(AuthViewModel())
}
