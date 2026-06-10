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
        events.append(event)
        events.sort { $0.date < $1.date }
        save()
        scheduleNotification(for: event)
    }

    func delete(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["schedule-1h-\(id.uuidString)"]
        )
        events.removeAll { $0.id == id }
        save()
    }

    func eventsOn(_ date: Date) -> [ScheduleEvent] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    var upcomingEvents: [ScheduleEvent] {
        events.filter { $0.date > Date() }
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
