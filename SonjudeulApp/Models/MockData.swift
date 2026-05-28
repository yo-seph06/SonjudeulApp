import Foundation

struct MockData {
    static let reports: [Report] = [
        Report(
            date: "2025년 4월 28일",
            summary: "카카오톡, 갤러리 교육 완료",
            mentorName: "박지수",
            mentorNote: "어머니께서 오늘 카카오톡 사진 전송을 처음 성공하시고는 너무 좋아하셨어요. 다음엔 배달앱 주문도 도전해보기로 했습니다 😊",
            checklist: [
                "카카오톡 사진 전송 완료",
                "갤러리 폴더 정리 완료",
                "스팸 문자 42건 삭제",
                "글씨 크기 조절 완료"
            ],
            nextItems: ["배달앱 주문", "KTX 예매"]
        ),
        Report(
            date: "2025년 4월 14일",
            summary: "배달앱 주문 교육 완료",
            mentorName: "박지수",
            mentorNote: "처음엔 어려워하셨는데 두 번 시도하시니 바로 주문을 성공하셨어요. 이제 혼자서도 잘 하실 수 있을 것 같아요 😄",
            checklist: [
                "배달앱 설치 및 로그인 완료",
                "첫 주문 성공",
                "결제 방법 설정 완료"
            ],
            nextItems: ["카카오택시", "병원 예약"]
        ),
        Report(
            date: "2025년 3월 31일",
            summary: "보이스피싱 예방 교육 완료",
            mentorName: "박지수",
            mentorNote: "최근 보이스피싱 사례를 함께 살펴보고, 의심 전화 차단 방법을 설정했어요. 앞으로는 안전하게 전화를 받으실 수 있을 것 같아요 💪",
            checklist: [
                "의심 번호 차단 설정 완료",
                "보이스피싱 유형 학습 완료",
                "가족 안심 번호 등록 완료"
            ],
            nextItems: ["스팸 차단 앱", "공공 와이파이 보안"]
        )
    ]

    static let mentor = Mentor(
        name: "박지수",
        university: "연세대학교 사회복지학과 3학년",
        rating: 5.0,
        reviewCount: 47,
        badges: ["신원인증 ✓", "범죄기록 조회 ✓", "교육 이수 ✓"]
    )

    static let subscription = Subscription(
        plan: "안심 정기구독",
        nextVisit: "2025년 5월 12일 (월) 오후 2시",
        nextPayment: "2025년 6월 1일",
        totalVisits: 8
    )
}
