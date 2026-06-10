import Foundation

struct ScheduleEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var notes: String = ""
}
