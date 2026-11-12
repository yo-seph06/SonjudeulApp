import Foundation
import SwiftUI

class ReportViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var mentorNote: String = ""
    @Published var completedItems: Set<String> = []
    @Published var nextRecommendations: Set<String> = []
    @Published var reportSent: Bool = false

    /// 자녀 신청의 과목 선택과 같은 목록을 쓴다 (LessonSubject.all)
    let curriculumItems = LessonSubject.all.map(\.name)

    let recommendItems = ["배달앱 주문", "KTX 예매", "카카오택시", "병원 예약", "스팸 차단 앱"]

    func toggleCompleted(_ item: String) {
        if completedItems.contains(item) {
            completedItems.remove(item)
        } else {
            completedItems.insert(item)
        }
    }

    func toggleRecommendation(_ item: String) {
        if nextRecommendations.contains(item) {
            nextRecommendations.remove(item)
        } else {
            nextRecommendations.insert(item)
        }
    }

    func sendReport() {
        reportSent = true
        mentorNote = ""
        completedItems = []
        nextRecommendations = []
    }
}
