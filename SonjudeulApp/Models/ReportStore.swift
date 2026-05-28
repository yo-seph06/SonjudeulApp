import Foundation
import UserNotifications

class ReportStore: ObservableObject {
    @Published var reports: [Report] = []

    func add(_ report: Report) {
        reports.insert(report, at: 0)
        scheduleReportNotification(mentorName: report.mentorName)
    }

    func reports(forChild id: UUID) -> [Report] {
        reports.filter { $0.childId == id }
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
