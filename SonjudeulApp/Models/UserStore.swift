import Foundation

enum RegistrationError: Error, Equatable {
    case invalidUsername
    case duplicateUsername
    case duplicateEmail

    var message: String {
        switch self {
        case .invalidUsername:   return "아이디는 영문, 숫자, 밑줄(_) 4~20자로 입력해주세요."
        case .duplicateUsername: return "이미 사용 중인 아이디입니다."
        case .duplicateEmail:    return "이미 사용 중인 이메일입니다."
        }
    }
}

enum AccountError: Error, Equatable {
    case notAuthorized
    case notFound
    case wrongPassword
    case adminProtected
}

/// 관리자 화면에 보여줄 회원 요약 (비밀번호·연락처 등 민감 정보 제외)
struct MemberSummary: Identifiable, Equatable {
    let id: UUID
    let number: Int
    let role: UserRole
    let name: String
    let username: String
    let createdAt: Date?
    let isWithdrawn: Bool
}

class UserStore {
    static let shared = UserStore()

    /// 기본 관리자 계정 (최초 실행 시 1회 생성). 비밀번호는 해시로만 보관한다.
    static let defaultAdminId = UUID(uuidString: "5A0D1E00-0000-4000-8000-00000000AD01")!
    private static let defaultAdminPasswordHash =
        "pbkdf2_sha256$120000$4Ko0opqb4kXMmWdSwCtApQ==$W/45RiFrd4Ja+jUXDM89SRMW/n9a4MRvuG+TbTlY2ps="

    private let fileURL: URL
    private(set) var users: [User] = []

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

    /// 저장 단계에서 아이디/이메일 중복을 다시 확인한 뒤, 기존 목록에 추가만 한다.
    func register(_ user: User) throws {
        let username = user.username.trimmingCharacters(in: .whitespaces)
        guard username.range(of: "^[A-Za-z0-9_]{4,20}$", options: .regularExpression) != nil else {
            throw RegistrationError.invalidUsername
        }
        // 탈퇴 회원의 아이디도 재사용 불가 (다른 사람이 같은 아이디로 가장하는 것 방지)
        if usernameExists(username) { throw RegistrationError.duplicateUsername }
        if emailExists(user.email) { throw RegistrationError.duplicateEmail }

        var newUser = user
        newUser.username = username
        newUser.email = user.email.trimmingCharacters(in: .whitespaces)
        newUser.authority = .user   // 회원가입으로는 관리자 권한을 얻을 수 없음
        users.append(newUser)
        save()
    }

    func emailExists(_ email: String) -> Bool {
        let target = normalized(email)
        return users.contains { $0.isActive && normalized($0.email) == target }
    }

    func usernameExists(_ username: String) -> Bool {
        let target = normalized(username)
        return users.contains { normalized($0.username) == target }
    }

    // MARK: - 로그인

    /// 이메일(@ 포함) 또는 아이디로 정확히 한 명의 활성 회원을 찾고 비밀번호 해시를 검증한다.
    func authenticate(identifier: String, password: String) -> User? {
        let id = normalized(identifier)
        guard !id.isEmpty else { return nil }
        let candidate: User?
        if id.contains("@") {
            candidate = users.first { $0.isActive && normalized($0.email) == id }
        } else {
            candidate = users.first { $0.isActive && normalized($0.username) == id }
        }
        guard let user = candidate,
              PasswordHasher.verify(password, against: user.passwordHash) else { return nil }
        return user
    }

    /// 활성 회원만 반환 (탈퇴 회원 정보는 다른 화면에 노출되지 않음)
    func findUserById(_ id: UUID) -> User? {
        users.first { $0.id == id && $0.isActive }
    }

    // MARK: - 아이디/비밀번호 찾기

    func findUserByNameAndPhone(name: String, phone: String) -> User? {
        let target = digits(phone)
        return users.first {
            $0.isActive && !$0.isAdmin && $0.name == name && digits($0.phone) == target
        }
    }

    func findUserByIdentifierAndPhone(identifier: String, phone: String) -> User? {
        let id = normalized(identifier)
        let target = digits(phone)
        return users.first {
            $0.isActive && !$0.isAdmin
            && (normalized($0.email) == id || normalized($0.username) == id)
            && digits($0.phone) == target
        }
    }

    func resetPassword(userId: UUID, newPassword: String) {
        guard let idx = users.firstIndex(where: { $0.id == userId && $0.isActive }) else { return }
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

    /// 프로필 항목만 갱신한다. 권한·비밀번호·아이디 등은 이 경로로 바꿀 수 없다.
    @discardableResult
    func updateProfile(_ updated: User) -> User? {
        guard let idx = users.firstIndex(where: { $0.id == updated.id && $0.isActive }) else { return nil }
        users[idx].name = updated.name
        users[idx].phone = updated.phone
        users[idx].university = updated.university
        users[idx].profileImageData = updated.profileImageData
        save()
        return users[idx]
    }

    // MARK: - 회원 탈퇴

    /// 본인 계정만, 비밀번호 확인 후 탈퇴 처리한다. 관리자 계정은 탈퇴할 수 없다.
    /// 기록은 탈퇴 상태로 남기고(아이디 재사용 방지), 개인정보와 비밀번호는 지운다.
    func withdraw(userId: UUID, requestedBy requesterId: UUID, password: String) throws {
        guard userId == requesterId else { throw AccountError.notAuthorized }
        guard let idx = users.firstIndex(where: { $0.id == userId && $0.isActive }) else {
            throw AccountError.notFound
        }
        guard !users[idx].isAdmin else { throw AccountError.adminProtected }
        guard PasswordHasher.verify(password, against: users[idx].passwordHash) else {
            throw AccountError.wrongPassword
        }
        users[idx].withdrawnAt = Date()
        users[idx].passwordHash = ""
        users[idx].email = ""
        users[idx].phone = ""
        users[idx].profileImageData = nil
        users[idx].university = nil
        save()
    }

    // MARK: - 관리자

    func isAdmin(_ userId: UUID?) -> Bool {
        guard let userId else { return false }
        return findUserById(userId)?.isAdmin == true
    }

    /// 관리자만 호출 가능. 요청자의 권한을 저장소 기준으로 다시 확인한다.
    func memberList(requestedBy requesterId: UUID?) throws -> [MemberSummary] {
        guard isAdmin(requesterId) else { throw AccountError.notAuthorized }
        return users
            .filter { !$0.isAdmin }
            .enumerated()
            .map { index, user in
                MemberSummary(id: user.id, number: index + 1, role: user.role, name: user.name,
                              username: user.username, createdAt: user.createdAt,
                              isWithdrawn: !user.isActive)
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

    private func digits(_ s: String) -> String {
        s.filter(\.isNumber)
    }

    private func ensureDefaultAdmin() {
        guard !users.contains(where: { $0.isAdmin }) else { return }
        users.append(User(
            id: Self.defaultAdminId, name: "관리자", username: "admin",
            email: "admin@sonjudeul.app", passwordHash: Self.defaultAdminPasswordHash,
            phone: "", role: .child, authority: .admin,
            birthDate: Date(timeIntervalSince1970: 0), gender: .female
        ))
    }

    private func save() {
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
                users = decoded
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
