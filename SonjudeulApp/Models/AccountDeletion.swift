import Foundation

/// 회원 탈퇴 정책: 탈퇴 신청 → 즉시 비활성화(DELETION_PENDING) → 3일 유예 → 영구 삭제
enum DeletionPolicy {
    static let gracePeriodDays = 3

    static func scheduledDeletionDate(from requestedAt: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: gracePeriodDays, to: requestedAt)
            ?? requestedAt.addingTimeInterval(TimeInterval(gracePeriodDays * 86_400))
    }

    /// 현재 시각 기준 남은 기간 (달력 날짜 기준)
    /// 예: 삭제 예정일이 3일 뒤 → "3일 남음", 오늘 → "오늘 삭제 예정", 이미 지남 → "삭제 대기"
    static func remainingLabel(until scheduledAt: Date, now: Date = Date(),
                               calendar: Calendar = .current) -> String {
        guard scheduledAt > now else { return "삭제 대기" }
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: scheduledAt)).day ?? 0
        return days <= 0 ? "오늘 삭제 예정" : "\(days)일 남음"
    }

    static func dateTimeText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: date)
    }
}

/// 유예기간이 끝난 계정을 영구 삭제한다.
/// 회원 데이터(예약·리포트·일정)를 먼저 정리한 뒤 회원 정보를 삭제하므로, 중간에 앱이 종료되어도
/// 다음 실행 때 같은 계정이 다시 처리된다.
enum AccountPurger {
    @discardableResult
    static func purgeExpiredAccounts(userStore: UserStore = .shared,
                                     bookingStore: BookingStore,
                                     reportStore: ReportStore,
                                     scheduleStore: ScheduleStore,
                                     linkStore: MemberLinkStore = .shared,
                                     alertStore: AdminAlertStore = .shared,
                                     now: Date = Date()) -> [UUID] {
        let expired = userStore.accountsPastDeletionDate(now: now)
        guard !expired.isEmpty else { return [] }
        for user in expired {
            switch user.role {
            case .child:
                bookingStore.purgeData(forDeletedChild: user.id)
                reportStore.purgeReports(forDeletedChild: user.id)
            case .mentor:
                bookingStore.purgeData(forDeletedMentor: user.id)
                reportStore.anonymizeReports(forDeletedMentor: user.id)
            }
            scheduleStore.removeEvents(forOwner: user.id)
        }
        let ids = expired.map(\.id)
        linkStore.removeLinks(forDeletedMembers: Set(ids))
        userStore.permanentlyDelete(ids: ids, now: now)
        // 삭제된 회원의 개인정보는 남기지 않고 건수만 기록한다
        alertStore.anonymizeAlerts(forDeletedMembers: Set(ids))
        alertStore.record(key: "purge:" + ids.map(\.uuidString).sorted().joined(separator: ","),
                          category: .deletion, title: "탈퇴 계정 영구 삭제",
                          message: "유예기간이 끝난 탈퇴 회원 \(ids.count)명의 계정과 관련 데이터가 영구 삭제되었어요.",
                          occurredAt: now)
        return ids
    }
}
