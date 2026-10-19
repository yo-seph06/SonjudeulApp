import Foundation

/// 관리자가 지정한 자녀·멘토 연결. 회원 고유 ID로만 연결하므로 이름이 같아도 섞이지 않는다.
struct MemberLink: Identifiable, Codable, Equatable {
    let id: UUID
    let childId: UUID
    let mentorId: UUID
    let createdAt: Date
    /// 연결을 지정한 관리자 ID
    let createdBy: UUID
}

enum MemberLinkError: Error, Equatable {
    case notAuthorized
    case memberNotFound
    case wrongRole
    case inactiveMember
    case alreadyLinked
    case childAlreadyHasMentor
    case linkNotFound
    case reauthRequired
    case saveFailed

    var message: String {
        switch self {
        case .notAuthorized:         return "관리자만 연결을 변경할 수 있어요."
        case .memberNotFound:        return "회원 정보를 찾을 수 없어요. 목록을 새로고침해주세요."
        case .wrongRole:             return "자녀 회원과 멘토 회원끼리만 연결할 수 있어요."
        case .inactiveMember:        return "탈퇴 대기 중인 회원은 새로 연결할 수 없어요."
        case .alreadyLinked:         return "이미 연결된 회원이에요."
        case .childAlreadyHasMentor: return "이 자녀에게는 이미 담당 멘토가 있어요. 기존 연결을 먼저 해제해주세요."
        case .linkNotFound:          return "이미 해제된 연결이에요. 목록을 새로고침해주세요."
        case .reauthRequired:        return "연결을 해제하려면 관리자 비밀번호를 다시 확인해야 해요."
        case .saveFailed:            return "변경 사항을 저장하지 못했어요. 다시 시도해주세요."
        }
    }
}

/// 자녀·멘토 연결 저장소 (Documents/sonjudeul_member_links.json)
/// 연결 정책: 자녀 1명당 담당 멘토 1명, 멘토 1명은 여러 자녀를 맡을 수 있다.
/// 예약 기록(BookingRecord)의 멘토·자녀 정보와는 별개이며, 예약 기록은 변경하지 않는다.
final class MemberLinkStore: ObservableObject {
    static let shared = MemberLinkStore()
    static let maxMentorsPerChild = 1

    @Published private(set) var links: [MemberLink] = []

    private let fileURL: URL
    private let userStore: UserStore
    private let lock = NSRecursiveLock()

    private init() {
        fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sonjudeul_member_links.json")
        userStore = .shared
        load()
    }

    /// 테스트용: 지정한 파일·회원 저장소를 쓰는 독립 저장소
    init(fileURL: URL, userStore: UserStore) {
        self.fileURL = fileURL
        self.userStore = userStore
        load()
    }

    // MARK: - 조회

    func mentorIds(ofChild childId: UUID) -> [UUID] {
        links.filter { $0.childId == childId }.map(\.mentorId)
    }

    func childIds(ofMentor mentorId: UUID) -> [UUID] {
        links.filter { $0.mentorId == mentorId }.map(\.childId)
    }

    // MARK: - 연결 / 해제 (관리자 전용)

    /// 요청자 권한, 두 회원의 존재·역할·상태, 중복 연결을 저장소 기준으로 다시 확인한 뒤 연결 1건만 추가한다.
    @discardableResult
    func link(childId: UUID, mentorId: UUID, requestedBy adminId: UUID?, now: Date = Date()) throws -> MemberLink {
        lock.lock(); defer { lock.unlock() }
        guard let adminId, userStore.canUseAdminFeatures(adminId) else { throw MemberLinkError.notAuthorized }
        guard let child = userStore.users.first(where: { $0.id == childId }),
              let mentor = userStore.users.first(where: { $0.id == mentorId }),
              !child.isPastDeletionDate(now: now), !mentor.isPastDeletionDate(now: now)
        else { throw MemberLinkError.memberNotFound }
        guard child.memberType == .child, mentor.memberType == .mentor else { throw MemberLinkError.wrongRole }
        guard child.isActive, mentor.isActive else { throw MemberLinkError.inactiveMember }
        guard !links.contains(where: { $0.childId == childId && $0.mentorId == mentorId }) else {
            throw MemberLinkError.alreadyLinked
        }
        guard links.filter({ $0.childId == childId }).count < Self.maxMentorsPerChild else {
            throw MemberLinkError.childAlreadyHasMentor
        }

        let link = MemberLink(id: UUID(), childId: childId, mentorId: mentorId, createdAt: now, createdBy: adminId)
        try commit(links + [link])
        return link
    }

    /// 지정한 연결 1건만 해제한다. 다른 연결은 그대로 둔다.
    /// 관리자 재인증(최근 5분) 후에만 해제할 수 있다.
    func unlink(linkId: UUID, requestedBy adminId: UUID?, reauth: AdminReauthSession = .shared) throws {
        lock.lock(); defer { lock.unlock() }
        guard let adminId, userStore.canUseAdminFeatures(adminId) else { throw MemberLinkError.notAuthorized }
        guard reauth.isFresh(for: adminId) else { throw MemberLinkError.reauthRequired }
        guard links.contains(where: { $0.id == linkId }) else { throw MemberLinkError.linkNotFound }
        try commit(links.filter { $0.id != linkId })
    }

    /// 영구 삭제된 회원의 연결만 정리한다 (AccountPurger에서 호출)
    func removeLinks(forDeletedMembers ids: Set<UUID>) {
        lock.lock(); defer { lock.unlock() }
        let remaining = links.filter { !ids.contains($0.childId) && !ids.contains($0.mentorId) }
        guard remaining.count != links.count else { return }
        try? commit(remaining)
    }

    // MARK: - 저장

    /// 파일 저장에 성공한 경우에만 화면용 목록을 바꾼다.
    private func commit(_ newLinks: [MemberLink]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(newLinks)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            throw MemberLinkError.saveFailed
        }
        links = newLinks
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? decoder.decode([MemberLink].self, from: data) {
            links = decoded
        } else {
            // 읽을 수 없는 파일은 덮어쓰기 전에 백업해 기존 연결 정보를 잃지 않게 한다
            let backup = fileURL.deletingPathExtension().appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.copyItem(at: fileURL, to: backup)
        }
    }
}
