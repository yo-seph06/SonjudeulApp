import Foundation

struct Report: Identifiable, Codable {
    var id = UUID()
    var date: String
    var summary: String
    var mentorName: String
    var mentorNote: String
    var checklist: [String]
    var nextItems: [String]
    var bookingId: UUID?
    var childId: UUID?
    var mentorId: UUID?
}
