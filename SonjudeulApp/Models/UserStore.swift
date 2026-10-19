import Foundation

enum RegistrationError: Error, Equatable {
    case invalidUsername
    case duplicateUsername
    case duplicateEmail
    case invalidEmail
    case invalidPhone
    case duplicatePhone

    var message: String {
        switch self {
        case .invalidUsername:   return "아이디는 영문, 숫자, 밑줄(_) 4~20자로 입력해주세요."
        case .duplicateUsername: return "이미 사용 중인 아이디입니다."
        case .duplicateEmail:    return "이미 사용 중인 이메일입니다."
        case .invalidEmail:      return "이메일 형식이 올바르지 않아요. (예: example@email.com)"
        case .invalidPhone:      return "휴대전화 번호 형식이 올바르지 않아요. (예: 010-1234-5678)"
        // 어떤 회원이 쓰는 번호인지는 알려주지 않는다
        case .duplicatePhone:    return "이미 가입된 전화번호예요. 기존 계정이 있다면 아이디 찾기를 이용해주세요."
        }
    }
}

enum AccountError: Error, Equatable {
    case notAuthorized
    case notFound
    case wrongPassword
    case adminProtected
    case notPendingDeletion
}

/// 관리자 화면에 보여줄 회원 요약 (비밀번호·연락처 등 민감 정보 제외)
struct MemberSummary: Identifiable, Equatable {
    let id: UUID
    let number: Int
    let memberType: MemberType
    let name: String
    let username: String
    let createdAt: Date?
    let status: AccountStatus
    let deletionRequestedAt: Date?
    let scheduledDeletionAt: Date?

    var isPendingDeletion: Bool { status == .deletionPending }
}

class UserStore {
    static let shared = UserStore()

    /// 기본 관리자 계정 (최초 실행 시 1회 생성). 비밀번호는 해시로만 보관한다.
    static let defaultAdminId = UUID(uuidString: "5A0D1E00-0000-4000-8000-00000000AD01")!
    private static let defaultAdminUsername = "rhksflwk1"
    private static let defaultAdminEmail = "rhksflwk1@"
    private static let defaultAdminPasswordHash =
        "pbkdf2_sha256$120000$mMOF+VyDD0Rac3yS4a2A9Q==$9d2YM+qfTGFrKX7+yb4Zkkk1lL5KiCFDbN4qDmphC74="
    /// 이전 버전의 기본 관리자 아이디 (새 관리자 정보로 교체 대상)
    private static let legacyAdminUsername = "admin"

    private let fileURL: URL
    private(set) var users: [User] = []
    /// 중복 확인과 저장을 한 번에 처리해, 동시에 가입해도 같은 이메일·전화번호가 두 번 들어가지 않게 한다.
    private let lock = NSRecursiveLock()

    private init() {
        fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sonjudeul_users.json")
        load()
        migrateLegacyDefaultsUsers()
    }

    /// 테스트용: 지정한 파일에 저장하는 독립 저장소
    init(fileURL: URL) {
        self.fileURL = fileURL
        load()
    }

    // MARK: - 회원가입

    /// 저장 단계에서 형식과 아이디/이메일/전화번호 중복을 다시 확인한 뒤, 기존 목록에 추가만 한다.
    /// 확인부터 저장까지 잠금 안에서 처리하므로 동시에 같은 값으로 가입해도 한 건만 저장된다.
    func register(_ user: User) throws {
        lock.lock(); defer { lock.unlock() }
        let username = user.username.trimmingCharacters(in: .whitespaces)
        guard username.range(of: "^[A-Za-z0-9_]{4,20}$", options: .regularExpression) != nil else {
            throw RegistrationError.invalidUsername
        }
        // 이메일은 선택 항목: 입력한 경우에만 형식과 중복을 확인한다
        let email = EmailRule.normalized(user.email)
        guard email.isEmpty || EmailRule.isValid(email) else { throw RegistrationError.invalidEmail }
        guard PhoneRule.isValid(user.phone) else { throw RegistrationError.invalidPhone }
        // 탈퇴 유예 중인 회원의 아이디·이메일·전화번호도 복구 가능성이 있으므로 재사용 불가
        if usernameExists(username) { throw RegistrationError.duplicateUsername }
        if !email.isEmpty && emailExists(email) { throw RegistrationError.duplicateEmail }
        if phoneExists(user.phone) { throw RegistrationError.duplicatePhone }

        var newUser = user
        newUser.username = username
        newUser.email = email
        newUser.phone = PhoneRule.formatted(user.phone)
        newUser.authority = .user   // 회원가입으로는 관리자 권한을 얻을 수 없음
        users.append(newUser)
        save()
    }

    func emailExists(_ email: String, excluding userId: UUID? = nil, now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let target = EmailRule.normalized(email)
        guard !target.isEmpty else { return false }
        return users.contains {
            $0.id != userId && !$0.isPastDeletionDate(now: now) && EmailRule.normalized($0.email) == target
        }
    }

    /// 하이픈·공백·국가번호 표기와 관계없이 같은 번호인지 비교한다.
    func phoneExists(_ phone: String, excluding userId: UUID? = nil, now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let target = PhoneRule.normalized(phone)
        guard !target.isEmpty else { return false }
        return users.contains {
            $0.id != userId && !$0.isPastDeletionDate(now: now) && PhoneRule.normalized($0.phone) == target
        }
    }

    func usernameExists(_ username: String, now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let target = normalized(username)
        return users.contains { !$0.isPastDeletionDate(now: now) && normalized($0.username) == target }
    }

    /// 이미 저장된 데이터에서 같은 이메일·전화번호를 쓰는 계정 묶음 수 (계정 정보는 돌려주지 않음)
    func duplicateContactGroupCount(now: Date = Date()) -> (email: Int, phone: Int) {
        lock.lock(); defer { lock.unlock() }
        let live = users.filter { !$0.isPastDeletionDate(now: now) }
        func groups(_ key: (User) -> String) -> Int {
            Dictionary(grouping: live.map(key).filter { !$0.isEmpty }, by: { $0 }).values.filter { $0.count > 1 }.count
        }
        return (groups { EmailRule.normalized($0.email) }, groups { PhoneRule.normalized($0.phone) })
    }

    // MARK: - 로그인

    /// 정상 회원만 로그인 성공으로 본다.
    func authenticate(identifier: String, password: String, now: Date = Date()) -> User? {
        guard let user = verifyCredentials(identifier: identifier, password: password, now: now),
              user.isActive else { return nil }
        return user
    }

    /// 이메일(@ 포함) 또는 아이디로 정확히 한 명을 찾고 비밀번호 해시를 검증한다.
    /// 정상 회원과 "유예기간이 남은 탈퇴 대기 회원"만 대상이다. 유예기간이 지난 계정은 찾지 않는다.
    func verifyCredentials(identifier: String, password: String, now: Date = Date()) -> User? {
        let id = normalized(identifier)
        guard !id.isEmpty else { return nil }
        let candidates = users.filter { $0.isActive || ($0.isPendingDeletion && !$0.isPastDeletionDate(now: now)) }
        let candidate: User?
        if id.contains("@") {
            candidate = candidates.first { normalized($0.email) == id }
        } else {
            candidate = candidates.first { normalized($0.username) == id }
        }
        guard let user = candidate,
              PasswordHasher.verify(password, against: user.passwordHash) else { return nil }
        return user
    }

    /// 정상 회원만 반환 (탈퇴 대기·삭제 회원 정보는 다른 화면에 노출되지 않음)
    func findUserById(_ id: UUID) -> User? {
        users.first { $0.id == id && $0.isActive }
    }

    /// 아이디/비밀번호 찾기에 쓰는 대상: 정상 회원 + 복구 가능한 탈퇴 대기 회원
    private func isRecoverable(_ user: User, now: Date) -> Bool {
        user.isActive || (user.isPendingDeletion && !user.isPastDeletionDate(now: now))
    }

    // MARK: - 아이디/비밀번호 찾기

    func findUserByNameAndPhone(name: String, phone: String, now: Date = Date()) -> User? {
        let target = PhoneRule.normalized(phone)
        return users.first {
            isRecoverable($0, now: now) && !$0.isAdmin && $0.name == name && PhoneRule.normalized($0.phone) == target
        }
    }

    func findUserByIdentifierAndPhone(identifier: String, phone: String, now: Date = Date()) -> User? {
        let id = normalized(identifier)
        let target = PhoneRule.normalized(phone)
        return users.first {
            isRecoverable($0, now: now) && !$0.isAdmin
            && (normalized($0.email) == id || normalized($0.username) == id)
            && PhoneRule.normalized($0.phone) == target
        }
    }

    /// 탈퇴 대기 회원도 비밀번호를 잊었을 때 재설정 후 로그인해서 복구할 수 있다.
    func resetPassword(userId: UUID, newPassword: String, now: Date = Date()) {
        guard let idx = users.firstIndex(where: { $0.id == userId && isRecoverable($0, now: now) }) else { return }
        users[idx].passwordHash = PasswordHasher.hash(newPassword)
        save()
    }

    func changePassword(userId: UUID, current: String, new newPassword: String) throws {
        guard let idx = users.firstIndex(where: { $0.id == userId && $0.isActive }) else {
            throw AccountError.notFound
        }
        guard PasswordHasher.verify(current, against: users[idx].passwordHash) else {
            throw AccountError.wrongPassword
        }
        users[idx].passwordHash = PasswordHasher.hash(newPassword)
        save()
    }

    // MARK: - 프로필 수정

    /// 프로필 항목만 갱신한다. 권한·비밀번호·아이디·이메일 등은 이 경로로 바꿀 수 없다.
    /// 전화번호를 바꾸는 경우에만 형식과 다른 회원과의 중복을 저장 단계에서 다시 확인한다.
    @discardableResult
    func updateProfile(_ updated: User) throws -> User {
        lock.lock(); defer { lock.unlock() }
        guard let idx = users.firstIndex(where: { $0.id == updated.id && $0.isActive }) else {
            throw AccountError.notFound
        }
        if PhoneRule.normalized(updated.phone) != PhoneRule.normalized(users[idx].phone) {
            guard PhoneRule.isValid(updated.phone) else { throw RegistrationError.invalidPhone }
            if phoneExists(updated.phone, excluding: updated.id) { throw RegistrationError.duplicatePhone }
            users[idx].phone = PhoneRule.formatted(updated.phone)
        }
        users[idx].name = updated.name
        users[idx].university = updated.university
        users[idx].profileImageData = updated.profileImageData
        save()
        return users[idx]
    }

    // MARK: - 회원 탈퇴 (3일 유예)

    /// 본인 계정만, 비밀번호 확인 후 탈퇴를 신청한다. 관리자 계정은 탈퇴할 수 없다.
    /// 계정은 즉시 비활성화되지만 데이터는 유예기간 동안 그대로 보관해 복구할 수 있게 한다.
    @discardableResult
    func requestDeletion(userId: UUID, requestedBy requesterId: UUID, password: String,
                         now: Date = Date()) throws -> User {
        guard userId == requesterId else { throw AccountError.notAuthorized }
        guard let idx = users.firstIndex(where: { $0.id == userId && $0.isActive }) else {
            throw AccountError.notFound
        }
        guard !users[idx].isAdmin else { throw AccountError.adminProtected }
        guard PasswordHasher.verify(password, against: users[idx].passwordHash) else {
            throw AccountError.wrongPassword
        }
        users[idx].accountStatus = .deletionPending
        users[idx].deletionRequestedAt = now
        users[idx].scheduledDeletionAt = DeletionPolicy.scheduledDeletionDate(from: now)
        save()
        return users[idx]
    }

    /// 유예기간 안에 아이디·비밀번호를 다시 확인한 경우에만 정상 회원으로 되돌린다.
    @discardableResult
    func restoreAccount(identifier: String, password: String, now: Date = Date()) throws -> User {
        guard let user = verifyCredentials(identifier: identifier, password: password, now: now),
              let idx = users.firstIndex(where: { $0.id == user.id }) else {
            throw AccountError.notFound
        }
        guard users[idx].isPendingDeletion else { throw AccountError.notPendingDeletion }
        users[idx].accountStatus = .active
        users[idx].deletionRequestedAt = nil
        users[idx].scheduledDeletionAt = nil
        save()
        return users[idx]
    }

    /// 유예기간이 끝나 영구 삭제해야 하는 계정
    func accountsPastDeletionDate(now: Date = Date()) -> [User] {
        users.filter { !$0.isAdmin && $0.isPastDeletionDate(now: now) }
    }

    /// 회원 정보를 저장소에서 완전히 지운다. 유예기간이 끝난 계정만 지워지도록 다시 확인한다.
    func permanentlyDelete(ids: [UUID], now: Date = Date()) {
        let targets = Set(ids)
        let before = users.count
        users.removeAll { targets.contains($0.id) && !$0.isAdmin && $0.isPastDeletionDate(now: now) }
        if users.count != before { save() }
    }

    // MARK: - 관리자

    func isAdmin(_ userId: UUID?) -> Bool {
        guard let userId else { return false }
        return findUserById(userId)?.isAdmin == true
    }

    /// 관리자만 호출 가능. 요청자의 권한을 저장소 기준으로 다시 확인한다.
    /// 유예기간이 끝난 계정은 (영구 삭제 처리 전이라도) 명단에 포함하지 않는다.
    func memberList(requestedBy requesterId: UUID?, now: Date = Date()) throws -> [MemberSummary] {
        guard isAdmin(requesterId) else { throw AccountError.notAuthorized }
        return users
            .filter { !$0.isAdmin && !$0.isPastDeletionDate(now: now) }
            .enumerated()
            .map { index, user in
                MemberSummary(id: user.id, number: index + 1, memberType: user.memberType,
                              name: user.name, username: user.username, createdAt: user.createdAt,
                              status: user.accountStatus,
                              deletionRequestedAt: user.deletionRequestedAt,
                              scheduledDeletionAt: user.scheduledDeletionAt)
            }
    }

    // MARK: - 이전 버전 데이터

    /// 아주 이전 버전은 회원 목록을 UserDefaults("registeredUsers")에 평문 비밀번호와 함께 저장했다.
    /// 파일에 없는 회원만 옮겨 담고(비밀번호는 해시로 변환), 평문이 남은 키는 삭제한다.
    private func migrateLegacyDefaultsUsers() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "registeredUsers") else { return }
        // 읽지 못한 경우에는 데이터를 잃지 않도록 키를 지우지 않는다
        guard importLegacyUsers(from: data) != nil else { return }
        defaults.removeObject(forKey: "registeredUsers")
    }

    @discardableResult
    func importLegacyUsers(from data: Data) -> Int? {
        lock.lock(); defer { lock.unlock() }
        guard let legacy = try? JSONDecoder().decode([User].self, from: data) else { return nil }
        var imported = 0
        for user in legacy {
            let duplicate = users.contains { $0.id == user.id }
                || usernameExists(user.username)
                || (!user.email.isEmpty && emailExists(user.email))
            guard !duplicate else { continue }
            var copy = user
            copy.authority = .user
            users.append(copy)
            imported += 1
        }
        if imported > 0 { save() }
        return imported
    }

    // MARK: - 저장

    private func normalized(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func ensureDefaultAdmin() {
        // 이전 기본 관리자(admin)가 남아 있으면 새 관리자 아이디·이메일·비밀번호로 교체
        if let idx = users.firstIndex(where: { $0.isAdmin && $0.username == Self.legacyAdminUsername }),
           !users.contains(where: { normalized($0.username) == Self.defaultAdminUsername }) {
            users[idx].username = Self.defaultAdminUsername
            users[idx].email = Self.defaultAdminEmail
            users[idx].passwordHash = Self.defaultAdminPasswordHash
        }
        guard !users.contains(where: { $0.isAdmin }) else { return }
        users.append(User(
            id: Self.defaultAdminId, name: "관리자", username: Self.defaultAdminUsername,
            email: Self.defaultAdminEmail, passwordHash: Self.defaultAdminPasswordHash,
            phone: "", role: .child, authority: .admin,
            birthDate: Date(timeIntervalSince1970: 0), gender: .female
        ))
    }

    private func save() {
        lock.lock(); defer { lock.unlock() }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(users) {
            try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: fileURL) {
            if let decoded = try? decoder.decode([User].self, from: data) {
                // 이전 버전에서 즉시 탈퇴 처리된(DELETED) 계정은 남기지 않는다
                users = decoded.filter { $0.accountStatus != .deleted }
            } else {
                // 읽을 수 없는 파일은 덮어쓰기 전에 백업해 기존 회원정보를 잃지 않게 한다
                let backup = fileURL.deletingPathExtension()
                    .appendingPathExtension("backup-\(Int(Date().timeIntervalSince1970)).json")
                try? FileManager.default.copyItem(at: fileURL, to: backup)
            }
        }
        ensureDefaultAdmin()
        // 이전 형식(평문 비밀번호)을 해시 형식으로 다시 저장
        save()
    }
}
