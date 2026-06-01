import Foundation
import SwiftUI
import UserNotifications

struct BookingRecord: Identifiable, Codable {
    var id = UUID()
    let date: String
    let rawDate: Date
    let plan: String
    var status: String
    var mentorId: UUID? = nil
    var mentorName: String = ""
    var childId: UUID? = nil
    var rating: Int? = nil
    var reviewComment: String = ""
    var reportWritten: Bool = false

    var statusColor: Color {
        switch status {
        case "예약 확정":   return .sonjuSuccess
        case "멘토 찾는 중": return Color(hex: "#FF9800")
        default:           return Color(hex: "#6B6B6B")
        }
    }
}

class BookingStore: ObservableObject {
    @Published var bookings: [BookingRecord] = []

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sonjudeul_bookings.json")
    }

    init() { load() }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(bookings) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([BookingRecord].self, from: data) else { return }
        bookings = decoded
    }

    func add(_ record: BookingRecord) {
        bookings.insert(record, at: 0)
        save()
    }

    func markVisited(id: UUID) {
        if let idx = bookings.firstIndex(where: { $0.id == id }) {
            bookings[idx].status = "방문 완료"
            save()
            scheduleVisitCompleteNotification()
        }
    }

    func markReportWritten(id: UUID) {
        if let idx = bookings.firstIndex(where: { $0.id == id }) {
            bookings[idx].reportWritten = true
            save()
        }
    }

    func acceptBooking(id: UUID, mentorId: UUID, mentorName: String) {
        if let idx = bookings.firstIndex(where: { $0.id == id }) {
            bookings[idx].status = "예약 확정"
            bookings[idx].mentorId = mentorId
            bookings[idx].mentorName = mentorName
            save()
            scheduleMentorMatchedNotification(mentorName: mentorName)
            scheduleOneHourBeforeNotification(booking: bookings[idx])
        }
    }

    func rateBooking(id: UUID, rating: Int, comment: String = "") {
        if let idx = bookings.firstIndex(where: { $0.id == id }) {
            bookings[idx].rating = rating
            bookings[idx].reviewComment = comment
            save()
        }
    }

    // MARK: - Mentor rating

    func reviews(forMentor id: UUID) -> [BookingRecord] {
        bookings.filter { $0.mentorId == id && $0.rating != nil }
    }

    func averageRating(forMentor id: UUID) -> Double {
        let rated = reviews(forMentor: id)
        guard !rated.isEmpty else { return 5.0 }
        let total = rated.compactMap { $0.rating }.reduce(0, +)
        return Double(total) / Double(rated.count)
    }

    func visitCount(forMentor id: UUID) -> Int {
        bookings.filter { $0.mentorId == id && $0.status == "방문 완료" }.count
    }

    // MARK: - Child side

    var nextBooking: BookingRecord? {
        bookings.first(where: { $0.status == "예약 확정" })
    }

    var todayBooking: BookingRecord? {
        let cal = Calendar.current
        return bookings.first(where: {
            $0.status == "예약 확정" && cal.isDateInToday($0.rawDate)
        })
    }

    func completedThisMonth() -> [BookingRecord] {
        let cal = Calendar.current
        let now = Date()
        return bookings.filter {
            $0.status == "방문 완료" &&
            cal.isDate($0.rawDate, equalTo: now, toGranularity: .month)
        }
    }

    // MARK: - Mentor side

    func bookings(forMentor id: UUID) -> [BookingRecord] {
        bookings.filter { $0.mentorId == id }
    }

    func todayBooking(forMentor id: UUID) -> BookingRecord? {
        let cal = Calendar.current
        return bookings(forMentor: id).first(where: {
            $0.status == "예약 확정" && cal.isDateInToday($0.rawDate)
        })
    }

    func completedThisMonth(forMentor id: UUID) -> [BookingRecord] {
        let cal = Calendar.current
        let now = Date()
        return bookings(forMentor: id).filter {
            $0.status == "방문 완료" &&
            cal.isDate($0.rawDate, equalTo: now, toGranularity: .month)
        }
    }

    // MARK: - Notifications

    private func scheduleOneHourBeforeNotification(booking: BookingRecord) {
        let fireDate = booking.rawDate.addingTimeInterval(-3600)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "1시간 후 방문 예정 🔔"
        content.body = "\(booking.mentorName.isEmpty ? "멘토" : booking.mentorName) 방문이 1시간 후예요! 준비해주세요."
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "visit-1h-\(booking.id.uuidString)", content: content, trigger: trigger)
        )
    }

    private func scheduleMentorMatchedNotification(mentorName: String) {
        let content = UNMutableNotificationContent()
        content.title = "멘토가 매칭되었습니다! 🎉"
        content.body = "\(mentorName) 멘토가 요청을 수락했어요. 예약이 확정되었습니다!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }

    private func scheduleVisitCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "방문이 완료되었습니다 ✅"
        content.body = "멘토 선생님이 방문을 완료했어요. 리포트를 확인해보세요!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }
}
