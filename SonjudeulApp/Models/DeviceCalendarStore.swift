import Foundation
import EventKit
import UIKit

/// 휴대전화 기본 캘린더(EventKit)에서 읽은 일정. 화면 표시용으로 메모리에만 두고 파일·서버에 저장하지 않는다.
struct DeviceCalendarEvent: Identifiable, Equatable {
    /// 반복 일정은 회차마다 eventIdentifier가 같으므로 시작 시각을 붙여 구분한다
    let id: String
    let eventIdentifier: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let location: String?
    let calendarTitle: String
    let isRecurring: Bool
    /// 손주들 앱에서 기기 캘린더로 내보낸 일정이면 원본 손주들 일정 ID
    let sonjudeulScheduleId: UUID?
}

enum DeviceCalendarError: LocalizedError {
    case noAccess
    case noDefaultCalendar
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .noAccess:          return "캘린더 접근 권한이 없어요. 설정 > 손주들 > 캘린더에서 '전체 접근'을 허용해주세요."
        case .noDefaultCalendar: return "일정을 추가할 기본 캘린더를 찾지 못했어요. 캘린더 앱에서 기본 캘린더를 확인해주세요."
        case .saveFailed:        return "기기 캘린더에 일정을 저장하지 못했어요. 손주들 일정은 그대로 저장되었어요."
        }
    }
}

/// 휴대전화 기본 캘린더 연동.
/// - 회원이 이 기기에서 직접 연동을 켠 경우에만 읽는다 (회원별·기기별 설정). 다른 회원으로 로그인하면 보이지 않는다.
/// - 읽은 일정은 손주들 일정 저장소와 섞지 않고 출처를 구분해 표시한다.
@MainActor
final class DeviceCalendarStore: ObservableObject {
    enum Access: Equatable {
        case notDetermined, granted, denied, writeOnly
    }

    @Published private(set) var access: Access
    @Published private(set) var isEnabled = false
    @Published private(set) var events: [DeviceCalendarEvent] = []
    @Published var lastError: String?

    private let store = EKEventStore()
    private var ownerId: UUID?
    private var loadedRange: DateInterval?
    private var changeObserver: NSObjectProtocol?

    static let scheduleURLPrefix = "sonjudeul://schedule/"

    init() {
        access = Self.currentAccess()
        // 기기 캘린더에서 일정이 추가·수정·삭제되면 다시 읽는다
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
    }

    deinit {
        if let changeObserver { NotificationCenter.default.removeObserver(changeObserver) }
    }

    var canWrite: Bool { isEnabled && access == .granted }

    // MARK: - 회원별 설정

    private static func enabledKey(_ id: UUID) -> String { "deviceCalendarEnabled.\(id.uuidString)" }

    /// 로그인한 회원이 바뀔 때 호출. 이전 회원에게 보이던 기기 일정은 즉시 지운다.
    func activate(for userId: UUID?) {
        ownerId = userId
        events = []
        lastError = nil
        isEnabled = userId.map { UserDefaults.standard.bool(forKey: Self.enabledKey($0)) } ?? false
        reload()
    }

    /// 사용자가 안내를 보고 연동을 켠 경우에만 시스템 권한을 요청한다.
    func enable() async {
        guard let ownerId else { return }
        if Self.currentAccess() == .notDetermined {
            do {
                _ = try await store.requestFullAccessToEvents()
            } catch {
                lastError = "캘린더 권한을 요청하지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }
        access = Self.currentAccess()
        guard access == .granted else { return }
        UserDefaults.standard.set(true, forKey: Self.enabledKey(ownerId))
        isEnabled = true
        reload()
    }

    func disable() {
        if let ownerId { UserDefaults.standard.removeObject(forKey: Self.enabledKey(ownerId)) }
        isEnabled = false
        events = []
    }

    // MARK: - 읽기

    /// 보고 있는 달과 앞뒤 한 달의 일정을 읽는다.
    func load(around month: Date) {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: month),
              let start = cal.date(byAdding: .month, value: -1, to: interval.start),
              let end = cal.date(byAdding: .month, value: 1, to: interval.end) else { return }
        loadedRange = DateInterval(start: start, end: end)
        reload()
    }

    /// 앱이 다시 활성화될 때: 계정(iCloud 등) 동기화를 요청하고 권한 변경을 반영한다.
    func refreshFromSystem() {
        store.refreshSourcesIfNecessary()
        reload()
    }

    func reload() {
        access = Self.currentAccess()
        guard isEnabled, ownerId != nil else { events = []; return }
        guard access == .granted else {
            events = []
            lastError = "캘린더 접근 권한이 꺼져 있어 기기 일정을 불러오지 못했어요. 손주들 일정은 그대로 볼 수 있어요."
            return
        }
        guard let range = loadedRange else { return }
        // predicateForEvents는 반복 일정을 기간 안의 회차별로 펼쳐서 돌려준다
        let predicate = store.predicateForEvents(withStart: range.start, end: range.end, calendars: nil)
        events = store.events(matching: predicate)
            .compactMap(Self.makeEvent)
            .sorted { $0.start < $1.start }
        lastError = nil
    }

    /// 해당 날짜에 걸친 기기 일정. 현재 로그인한 회원이 연동한 경우에만, 손주들에서 내보낸 내 일정은 빼고 돌려준다.
    func events(on date: Date, ownerId: UUID?, excluding ownScheduleIds: Set<UUID>) -> [DeviceCalendarEvent] {
        guard isEnabled, let ownerId, ownerId == self.ownerId else { return [] }
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        return events.filter { event in
            if let id = event.sonjudeulScheduleId, ownScheduleIds.contains(id) { return false }
            // 끝 시각이 0시 정각인 일정은 그 날에 표시하지 않는다
            let end = max(event.end, event.start.addingTimeInterval(1))
            return event.start < dayEnd && end > dayStart
        }
    }

    // MARK: - 쓰기 (손주들 일정 → 기기 캘린더)

    /// 손주들 일정을 기기 기본 캘린더에 추가하고 기기 일정 ID를 돌려준다.
    func export(_ event: ScheduleEvent) throws -> String {
        guard canWrite else { throw DeviceCalendarError.noAccess }
        guard let calendar = store.defaultCalendarForNewEvents else { throw DeviceCalendarError.noDefaultCalendar }
        let ekEvent = EKEvent(eventStore: store)
        ekEvent.calendar = calendar
        ekEvent.title = event.title
        ekEvent.startDate = event.date
        ekEvent.endDate = event.date.addingTimeInterval(3600)
        ekEvent.timeZone = TimeZone.current
        ekEvent.notes = event.notes.isEmpty ? nil : event.notes
        // 기기 캘린더에서 다시 읽을 때 손주들 일정과 같은 일정임을 알아보기 위한 표시
        ekEvent.url = URL(string: Self.scheduleURLPrefix + event.id.uuidString)
        do {
            try store.save(ekEvent, span: .thisEvent, commit: true)
        } catch {
            throw DeviceCalendarError.saveFailed
        }
        return ekEvent.eventIdentifier
    }

    /// 손주들에서 내보낸 일정만 기기 캘린더에서 지운다. (사용자가 직접 만든 일정은 건드리지 않음)
    func removeExported(_ event: ScheduleEvent) throws {
        guard canWrite else { throw DeviceCalendarError.noAccess }
        guard let identifier = event.deviceEventId,
              let ekEvent = store.event(withIdentifier: identifier),
              ekEvent.url?.absoluteString == Self.scheduleURLPrefix + event.id.uuidString else { return }
        try store.remove(ekEvent, span: .thisEvent, commit: true)
    }

    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - 내부

    private static func currentAccess() -> Access {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:     return .granted
        case .writeOnly:      return .writeOnly
        case .notDetermined:  return .notDetermined
        default:              return .denied
        }
    }

    private static func makeEvent(_ e: EKEvent) -> DeviceCalendarEvent? {
        guard let start = e.startDate, let end = e.endDate else { return nil }
        let identifier = e.eventIdentifier ?? e.calendarItemIdentifier
        var scheduleId: UUID?
        if let url = e.url?.absoluteString, url.hasPrefix(scheduleURLPrefix) {
            scheduleId = UUID(uuidString: String(url.dropFirst(scheduleURLPrefix.count)))
        }
        let title = (e.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let location = e.location?.trimmingCharacters(in: .whitespacesAndNewlines)
        return DeviceCalendarEvent(
            id: "\(identifier)|\(start.timeIntervalSince1970)",
            eventIdentifier: identifier,
            title: title.isEmpty ? "(제목 없음)" : title,
            start: start, end: end, isAllDay: e.isAllDay,
            location: (location?.isEmpty ?? true) ? nil : location,
            calendarTitle: e.calendar?.title ?? "캘린더",
            isRecurring: e.hasRecurrenceRules,
            sonjudeulScheduleId: scheduleId
        )
    }
}
