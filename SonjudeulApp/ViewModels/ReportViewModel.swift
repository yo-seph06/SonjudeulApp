import Foundation
import SwiftUI

class ReportViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var mentorNote: String = ""
    @Published var completedItems: Set<String> = []
    @Published var nextRecommendations: Set<String> = []
    @Published var reportSent: Bool = false

    let curriculumItems = [
        "핸드폰 최적화", "보안 설정 점검",
        "갤러리 사용법", "카카오톡 사진·영상 전송", "글씨 크기·밝기 조절",
        "배달앱 주문·결제", "KTX·고속버스 예매", "카카오택시", "병원 예약·모바일 처방전",
        "보이스피싱 대응법", "스팸·광고 차단 설정"
    ]

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
