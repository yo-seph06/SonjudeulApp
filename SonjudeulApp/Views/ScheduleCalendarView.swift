import SwiftUI

struct ScheduleCalendarView: View {
    @EnvironmentObject var scheduleStore: ScheduleStore
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var showAddSheet = false

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
                                                    dotCount: min(scheduleStore.eventsOn(date).count, 3),
                                                    weekday: col
                                                ) {
                                                    selectedDate = (selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false) ? nil : date
                                                }
                                            } else {
                                                Color.clear.frame(maxWidth: .infinity, minHeight: 52)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // 선택된 날짜 일정
                        if let selected = selectedDate {
                            let dayEvents = scheduleStore.eventsOn(selected)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(formatDate(selected))
                                        .font(.sonjuHeadline)
                                        .foregroundColor(.sonjuText)
                                    Spacer()
                                    Button {
                                        showAddSheet = true
                                    } label: {
                                        Label("추가", systemImage: "plus.circle.fill")
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuPrimary)
                                    }
                                }
                                .padding(.horizontal, 24)

                                if dayEvents.isEmpty {
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
                                    ForEach(dayEvents) { event in
                                        ScheduleEventCard(event: event)
                                            .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }

                        // 다가오는 일정
                        let upcoming = scheduleStore.upcomingEvents
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
            .navigationTitle("내 일정")
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
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: date)
    }
}

// MARK: - 일정 카드

struct ScheduleEventCard: View {
    @EnvironmentObject var scheduleStore: ScheduleStore
    let event: ScheduleEvent

    private var timeText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E) a h:mm"
        return f.string(from: event.date)
    }

    var body: some View {
        SonjuCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.sonjuPrimary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.sonjuPrimary)
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuText)
                    Text(timeText)
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                    if !event.notes.isEmpty {
                        Text(event.notes)
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button {
                    scheduleStore.delete(id: event.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.red.opacity(0.6))
                }
            }
        }
    }
}

#Preview {
    ScheduleCalendarView()
        .environmentObject(ScheduleStore())
}
