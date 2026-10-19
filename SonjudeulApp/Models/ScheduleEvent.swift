import Foundation

struct ScheduleEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var notes: String = ""
    /// 일정을 만든 회원의 고유 ID (이전 버전 일정은 nil → 아무에게도 표시하지 않음)
    var ownerId: UUID? = nil
    /// 기기 기본 캘린더에도 추가한 경우 그 일정의 ID (중복 표시 방지·함께 삭제용)
    var deviceEventId: String? = nil
}
