import Foundation
import UserNotifications

class ScheduleStore: ObservableObject {
    @Published var events: [ScheduleEvent] = []

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sonjudeul_schedule.json")
    }

    init() { load() }

    // MARK: - CRUD

    func add(_ event: ScheduleEvent) {
        guard event.ownerId != nil else { return }
        events.append(event)
        events.sort { $0.date < $1.date }
        save()
        scheduleNotification(for: event)
    }

    /// 본인 일정만 삭제할 수 있다.
    func delete(id: UUID, ownerId: UUID?) {
        guard let ownerId, events.contains(where: { $0.id == id && $0.ownerId == ownerId }) else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["schedule-1h-\(id.uuidString)"]
        )
        events.removeAll { $0.id == id }
        save()
    }

    // 조회는 항상 로그인한 회원의 ID로 거른다
    func events(forOwner ownerId: UUID?) -> [ScheduleEvent] {
        guard let ownerId else { return [] }
        return events.filter { $0.ownerId == ownerId }
    }

    func eventsOn(_ date: Date, ownerId: UUID?) -> [ScheduleEvent] {
        let cal = Calendar.current
        return events(forOwner: ownerId).filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    func upcomingEvents(ownerId: UUID?) -> [ScheduleEvent] {
        events(forOwner: ownerId).filter { $0.date > Date() }
    }

    func removeEvents(forOwner ownerId: UUID) {
        let ids = events.filter { $0.ownerId == ownerId }.map { "schedule-1h-\($0.id.uuidString)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        events.removeAll { $0.ownerId == ownerId }
        save()
    }

    /// 로그인한 회원의 일정 알림만 다시 등록한다.
    func rescheduleNotifications(for ownerId: UUID) {
        upcomingEvents(ownerId: ownerId).forEach { scheduleNotification(for: $0) }
    }

    // MARK: - Persistence

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(events) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([ScheduleEvent].self, from: data) else { return }
        events = decoded
    }

    // MARK: - Notification

    private func scheduleNotification(for event: ScheduleEvent) {
        let fireDate = event.date.addingTimeInterval(-3600)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "1시간 후 일정 알림 🔔"
        content.body = "'\(event.title)' 일정이 1시간 후에 시작돼요!"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: "schedule-1h-\(event.id.uuidString)",
                content: content,
                trigger: trigger
            )
        )
    }
}
