import Foundation

/// 관리자 알림 센터의 알림 1건. 실제 데이터나 실제로 일어난 작업에서만 만들어진다.
struct AdminAlert: Identifiable, Codable, Equatable {
    enum Category: String, Codable {
        case signup, deletion, link, dataIntegrity, security, adminAction

        var label: String {
            switch self {
            case .signup:        return "신규 가입"
            case .deletion:      return "회원 탈퇴"
            case .link:          return "연결 문제"
            case .dataIntegrity: return "데이터 점검"
            case .security:      return "보안"
            case .adminAction:   return "관리자 작업"
            }
        }
    }

    /// 알림을 눌렀을 때 이동할 화면
    enum Target: Codable, Equatable {
        case member(UUID)
        case linkManagement
        case scheduleManagement
    }

    let id: UUID
    /// 중복 방지용 고유 키 (같은 사건은 같은 키)
    let key: String
    let category: Category
    var title: String
    var message: String
    let occurredAt: Date
    var isRead: Bool
    var target: Target?
    /// 알림 문구에 이름이 들어간 회원 (영구 삭제 시 문구에서 개인정보를 지우는 데 쓴다)
    var relatedMemberIds: [UUID]?
}

/// 관리자 알림 저장소 (Documents/sonjudeul_admin_alerts.json)
/// - 저장된 회원·연결 데이터를 점검해 생기는 알림(refresh)과, 실제 작업 시점에 기록하는 알림(record)이 있다.
/// - 같은 키의 알림은 한 번만 만들고, 읽음 상태는 파일에 저장해 앱을 다시 켜도 유지한다.
/// - 알림 센터를 처음 쓰기 시작한 시각(baselineAt) 이전에 가입한 회원은 신규 가입 알림을 만들지 않는다.
final class AdminAlertStore: ObservableObject {
    static let shared = AdminAlertStore()
    /// 영구 삭제까지 이 시간 이내로 남으면 '삭제 임박' 알림
    static let deletionSoonWindow: TimeInterval = 24 * 3600

    @Published private var alerts: [AdminAlert] = []
    private var baselineAt = Date()

    private let fileURL: URL
    private let userStore: UserStore
    private let linkStore: MemberLinkStore
    private let lock = NSRecursiveLock()

    private struct Stored: Codable {
        var baselineAt: Date
        var alerts: [AdminAlert]
    }

    private init() {
        fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sonjudeul_admin_alerts.json")
        userStore = .shared
        linkStore = .shared
        load()
    }

    /// 테스트용: 지정한 파일·저장소를 쓰는 독립 저장소
    init(fileURL: URL, userStore: UserStore, linkStore: MemberLinkStore) {
        self.fileURL = fileURL
        self.userStore = userStore
        self.linkStore = linkStore
        load()
    }

    // MARK: - 조회·상태 변경 (관리자 전용)

    /// 최신순. 관리자가 아니면 빈 목록.
    func alerts(requestedBy adminId: UUID?) -> [AdminAlert] {
        guard userStore.isAdmin(adminId) else { return [] }
        return alerts.sorted { $0.occurredAt > $1.occurredAt }
    }

    func unreadCount(requestedBy adminId: UUID?) -> Int {
        guard userStore.isAdmin(adminId) else { return 0 }
        return alerts.filter { !$0.isRead }.count
    }

    func setRead(_ isRead: Bool, id: UUID, requestedBy adminId: UUID?) {
        lock.lock(); defer { lock.unlock() }
        guard userStore.isAdmin(adminId),
              let idx = alerts.firstIndex(where: { $0.id == id }), alerts[idx].isRead != isRead else { return }
        alerts[idx].isRead = isRead
        save()
    }

    func markAllRead(requestedBy adminId: UUID?) {
        lock.lock(); defer { lock.unlock() }
        guard userStore.isAdmin(adminId), alerts.contains(where: { !$0.isRead }) else { return }
        for idx in alerts.indices { alerts[idx].isRead = true }
        save()
    }

    // MARK: - 데이터 점검 (관리자 화면을 열거나 새로고침할 때)

    func refresh(requestedBy adminId: UUID?, now: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        guard let members = try? userStore.memberList(requestedBy: adminId, now: now) else { return }
        var added = false

        for member in members {
            // 신규 가입: 알림 센터 사용 시작 이후 가입한 회원만
            if let createdAt = member.createdAt, createdAt >= baselineAt {
                added = insert(key: "signup:\(member.id)", category: .signup,
                               title: "신규 회원 가입",
                               message: "\(member.memberType.label) 회원 \(member.name)(\(member.username))님이 가입했어요.",
                               occurredAt: createdAt, target: .member(member.id), related: [member.id]) || added
            }

            guard member.isPendingDeletion else { continue }
            let requestedAt = member.deletionRequestedAt ?? now
            let scheduledAt = member.scheduledDeletionAt ?? DeletionPolicy.scheduledDeletionDate(from: requestedAt)
            let episode = Int(requestedAt.timeIntervalSince1970)

            added = insert(key: "deletion-request:\(member.id):\(episode)", category: .deletion,
                           title: "회원 탈퇴 신청",
                           message: "\(member.name)(\(member.username))님이 탈퇴를 신청했어요. \(DeletionPolicy.dateTimeText(scheduledAt))에 영구 삭제될 예정이에요.",
                           occurredAt: requestedAt, target: .member(member.id), related: [member.id]) || added

            if scheduledAt.timeIntervalSince(now) <= Self.deletionSoonWindow {
                added = insert(key: "deletion-soon:\(member.id):\(episode)", category: .deletion,
                               title: "영구 삭제 임박",
                               message: "\(member.name)(\(member.username))님의 계정이 \(DeletionPolicy.dateTimeText(scheduledAt))에 영구 삭제돼요.",
                               occurredAt: max(requestedAt, scheduledAt.addingTimeInterval(-Self.deletionSoonWindow)),
                               target: .member(member.id), related: [member.id]) || added
            }

            // 연결 문제: 탈퇴 대기 회원이 포함된 자녀·멘토 연결 (영구 삭제되면 연결도 사라진다)
            for link in linkStore.links where link.childId == member.id || link.mentorId == member.id {
                let otherId = link.childId == member.id ? link.mentorId : link.childId
                let other = members.first { $0.id == otherId }
                let otherText = other.map { "\($0.memberType.label) \($0.name)(\($0.username))" } ?? "상대 회원"
                added = insert(key: "link-pending:\(link.id):\(member.id):\(episode)", category: .link,
                               title: "탈퇴 대기 회원이 포함된 연결",
                               message: "\(member.memberType.label) \(member.name)(\(member.username))님이 탈퇴 대기 중이에요. 영구 삭제되면 \(otherText)님과의 연결도 해제돼요.",
                               occurredAt: requestedAt, target: .linkManagement,
                               related: [link.childId, link.mentorId]) || added
            }
        }

        // 데이터 점검: 같은 이메일·전화번호를 쓰는 계정 (개인정보는 표시하지 않음)
        let dup = userStore.duplicateContactGroupCount(now: now)
        if dup.email > 0 || dup.phone > 0 {
            added = insert(key: "dup-contact:\(dup.email):\(dup.phone)", category: .dataIntegrity,
                           title: "중복 연락처 계정 발견",
                           message: "같은 이메일을 쓰는 계정 묶음 \(dup.email)개, 같은 전화번호를 쓰는 계정 묶음 \(dup.phone)개가 저장되어 있어요.",
                           occurredAt: now, target: nil) || added
        }

        if added { save() }
    }

    // MARK: - 실제 작업 시점 기록

    /// 같은 키가 이미 있으면 무시한다. 관리자가 직접 한 작업은 읽음 상태로 기록한다.
    func record(key: String, category: AdminAlert.Category, title: String, message: String,
                occurredAt: Date = Date(), target: AdminAlert.Target? = nil, isRead: Bool = false,
                relatedMemberIds: [UUID] = []) {
        lock.lock(); defer { lock.unlock() }
        if insert(key: key, category: category, title: title, message: message,
                  occurredAt: occurredAt, target: target, related: relatedMemberIds, isRead: isRead) {
            save()
        }
    }

    /// 영구 삭제된 회원이 언급된 알림은 남기되 이름·아이디가 들어간 문구와 이동 대상을 지운다.
    func anonymizeAlerts(forDeletedMembers ids: Set<UUID>) {
        lock.lock(); defer { lock.unlock() }
        var changed = false
        for idx in alerts.indices where alerts[idx].relatedMemberIds?.contains(where: ids.contains) == true {
            alerts[idx].message = "영구 삭제된 회원과 관련된 알림이에요. 개인정보는 삭제되었어요."
            alerts[idx].target = nil
            alerts[idx].relatedMemberIds = nil
            changed = true
        }
        if changed { save() }
    }

    @discardableResult
    private func insert(key: String, category: AdminAlert.Category, title: String, message: String,
                        occurredAt: Date, target: AdminAlert.Target?, related: [UUID] = [],
                        isRead: Bool = false) -> Bool {
        guard !alerts.contains(where: { $0.key == key }) else { return false }
        alerts.append(AdminAlert(id: UUID(), key: key, category: category, title: title, message: message,
                                 occurredAt: occurredAt, isRead: isRead, target: target,
                                 relatedMemberIds: related.isEmpty ? nil : related))
        return true
    }

    // MARK: - 저장

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(Stored(baselineAt: baselineAt, alerts: alerts)) {
            try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL) else {
            // 처음 사용: 지금부터 일어나는 가입만 신규 가입 알림으로 만든다
            baselineAt = Date()
            save()
            return
        }
        if let stored = try? decoder.decode(Stored.self, from: data) {
            baselineAt = stored.baselineAt
            alerts = stored.alerts
        } else {
            // 읽을 수 없는 파일은 백업해 기존 알림 상태를 잃지 않게 한다
            let backup = fileURL.deletingPathExtension()
                .appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.copyItem(at: fileURL, to: backup)
            baselineAt = Date()
            save()
        }
    }
}
