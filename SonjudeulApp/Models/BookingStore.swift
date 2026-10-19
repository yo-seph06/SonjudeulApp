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
        try? persist()
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(bookings)
        try data.write(to: fileURL, options: .atomic)
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

    // MARK: - Child side (항상 로그인한 자녀의 ID로 걸러서 사용)

    func bookings(forChild id: UUID) -> [BookingRecord] {
        bookings.filter { $0.childId == id }
    }

    func nextBooking(forChild id: UUID) -> BookingRecord? {
        bookings(forChild: id).first(where: { $0.status == "예약 확정" })
    }

    // MARK: - 영구 삭제 (탈퇴 유예기간 종료 후) / 로그인 전환

    /// 영구 삭제된 자녀의 진행 중인 예약은 삭제하고, 완료된 방문 기록은 자녀 정보와의 연결을 끊는다.
    /// (완료 기록은 개인정보 없이 날짜·플랜·평점만 남아 멘토 방문 횟수·평점 통계에 쓰인다)
    func purgeData(forDeletedChild id: UUID) {
        let pending = bookings.filter { $0.childId == id && $0.status != "방문 완료" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: pending.map { "visit-1h-\($0.id.uuidString)" }
        )
        bookings.removeAll { $0.childId == id && $0.status != "방문 완료" }
        for idx in bookings.indices where bookings[idx].childId == id {
            bookings[idx].childId = nil
        }
        save()
    }

    /// 영구 삭제된 멘토가 맡은 미완료 예약은 다시 멘토를 찾도록 되돌리고,
    /// 완료된 방문 기록에서는 멘토 이름과 연결을 지운다.
    func purgeData(forDeletedMentor id: UUID) {
        for idx in bookings.indices where bookings[idx].mentorId == id {
            if bookings[idx].status == "방문 완료" {
                bookings[idx].mentorName = "탈퇴한 멘토"
            } else {
                bookings[idx].status = "멘토 찾는 중"
                bookings[idx].mentorName = ""
            }
            bookings[idx].mentorId = nil
        }
        save()
    }

    /// 로그인한 회원의 확정 예약 알림만 다시 등록한다.
    func rescheduleNotifications(for userId: UUID) {
        bookings
            .filter { ($0.childId == userId || $0.mentorId == userId) && $0.status == "예약 확정" }
            .forEach { scheduleOneHourBeforeNotification(booking: $0) }
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

    // MARK: - 관리자 (방문 일정 관리)

    /// 방문 완료 기록은 평점·리포트·멘토 통계에 쓰이므로 관리자도 바꿀 수 없다.
    static func isAdminEditable(_ booking: BookingRecord) -> Bool {
        booking.status != "방문 완료" && !booking.reportWritten
    }

    /// 예약 화면(BookingCompleteView)과 같은 날짜 표시 형식
    static func displayDateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 (E) a h시"
        return f.string(from: date)
    }

    /// 관리자만 전체 방문 일정을 조회할 수 있다. 요청자의 권한은 회원 저장소 기준으로 다시 확인한다.
    func adminVisits(requestedBy adminId: UUID?, userStore: UserStore = .shared) throws -> [BookingRecord] {
        guard userStore.isAdmin(adminId) else { throw VisitAdminError.notAuthorized }
        return bookings
    }

    /// 미완료 방문 일정의 날짜·시간만 바꾼다. 다른 항목과 다른 일정은 그대로 둔다.
    /// 알림은 해당 회원이 다음에 로그인할 때 바뀐 시간으로 다시 등록된다.
    func adminReschedule(id: UUID, to newDate: Date, requestedBy adminId: UUID?,
                         userStore: UserStore = .shared, now: Date = Date()) throws {
        guard userStore.isAdmin(adminId) else { throw VisitAdminError.notAuthorized }
        guard let idx = bookings.firstIndex(where: { $0.id == id }) else { throw VisitAdminError.notFound }
        guard Self.isAdminEditable(bookings[idx]) else { throw VisitAdminError.completed }
        guard newDate > now else { throw VisitAdminError.pastDate }

        let previous = bookings[idx]
        let updated = BookingRecord(id: previous.id, date: Self.displayDateText(newDate), rawDate: newDate,
                                    plan: previous.plan, status: previous.status,
                                    mentorId: previous.mentorId, mentorName: previous.mentorName,
                                    childId: previous.childId, rating: previous.rating,
                                    reviewComment: previous.reviewComment, reportWritten: previous.reportWritten)
        bookings[idx] = updated
        do {
            try persist()
        } catch {
            bookings[idx] = previous
            throw VisitAdminError.saveFailed
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["visit-1h-\(id.uuidString)"])
    }

    /// 미완료 방문 일정 1건만 삭제한다.
    func adminDelete(id: UUID, requestedBy adminId: UUID?, userStore: UserStore = .shared) throws {
        guard userStore.isAdmin(adminId) else { throw VisitAdminError.notAuthorized }
        guard let idx = bookings.firstIndex(where: { $0.id == id }) else { throw VisitAdminError.notFound }
        guard Self.isAdminEditable(bookings[idx]) else { throw VisitAdminError.completed }

        let previous = bookings
        bookings.remove(at: idx)
        do {
            try persist()
        } catch {
            bookings = previous
            throw VisitAdminError.saveFailed
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["visit-1h-\(id.uuidString)"])
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

enum VisitAdminError: Error, Equatable {
    case notAuthorized
    case notFound
    case completed
    case pastDate
    case saveFailed

    var message: String {
        switch self {
        case .notAuthorized: return "관리자만 방문 일정을 관리할 수 있어요."
        case .notFound:      return "이미 삭제된 일정이에요. 목록을 새로고침해주세요."
        case .completed:     return "방문 완료된 일정은 수정하거나 삭제할 수 없어요."
        case .pastDate:      return "지금 이후의 날짜와 시간을 선택해주세요."
        case .saveFailed:    return "변경 사항을 저장하지 못했어요. 다시 시도해주세요."
        }
    }
}
