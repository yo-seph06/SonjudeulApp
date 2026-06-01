import Foundation
import UserNotifications

class ReportStore: ObservableObject {
    @Published var reports: [Report] = []

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sonjudeul_reports.json")
    }

    init() { load() }

    func add(_ report: Report) {
        reports.insert(report, at: 0)
        save()
        scheduleReportNotification(mentorName: report.mentorName)
    }

    func reports(forChild id: UUID) -> [Report] {
        reports.filter { $0.childId == id }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(reports) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([Report].self, from: data) else { return }
        reports = decoded
    }

    private func scheduleReportNotification(mentorName: String) {
        let content = UNMutableNotificationContent()
        content.title = "안부 리포트가 도착했어요 📋"
        content.body = "\(mentorName) 멘토가 리포트를 작성하였습니다. 확인해보세요!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
