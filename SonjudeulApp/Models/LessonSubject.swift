import Foundation

/// 수업 과목. 멘토 리포트의 교육 완료 항목과 자녀 신청의 수업 과목 선택이 이 목록 하나를 함께 쓴다.
/// 리포트에는 과목명(name)이 저장되므로 이름을 바꾸면 이전 리포트와 연결이 끊긴다. 이름은 바꾸지 않는다.
struct LessonSubject: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String

    static let all: [LessonSubject] = [
        LessonSubject(id: "phone-optimization", name: "핸드폰 최적화", icon: "speedometer"),
        LessonSubject(id: "security-check", name: "보안 설정 점검", icon: "lock.shield.fill"),
        LessonSubject(id: "gallery", name: "갤러리 사용법", icon: "photo.on.rectangle"),
        LessonSubject(id: "kakaotalk-media", name: "카카오톡 사진·영상 전송", icon: "paperplane.fill"),
        LessonSubject(id: "display-size", name: "글씨 크기·밝기 조절", icon: "textformat.size"),
        LessonSubject(id: "delivery-app", name: "배달앱 주문·결제", icon: "takeoutbag.and.cup.and.straw.fill"),
        LessonSubject(id: "train-bus-booking", name: "KTX·고속버스 예매", icon: "tram.fill"),
        LessonSubject(id: "kakao-taxi", name: "카카오택시", icon: "car.fill"),
        LessonSubject(id: "hospital-booking", name: "병원 예약·모바일 처방전", icon: "cross.case.fill"),
        LessonSubject(id: "voice-phishing", name: "보이스피싱 대응법", icon: "exclamationmark.shield.fill"),
        LessonSubject(id: "spam-block", name: "스팸·광고 차단 설정", icon: "nosign"),
    ]

    static let minimumSelection = 2

    static func find(id: String) -> LessonSubject? {
        all.first { $0.id == id }
    }

    /// 신청 저장 전 검증: 목록에 있는 과목만, 중복 없이, 최소 2개 (문제가 없으면 nil)
    static func validationError(_ subjects: [LessonSubject]) -> String? {
        let ids = subjects.map(\.id)
        guard Set(ids).count == ids.count, ids.allSatisfy({ find(id: $0) != nil }) else {
            return "선택한 과목 정보가 올바르지 않아요. 과목을 다시 선택해 주세요."
        }
        guard ids.count >= minimumSelection else {
            return "수업 과목을 최소 \(minimumSelection)개 이상 선택해 주세요."
        }
        return nil
    }
}
