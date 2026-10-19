import Foundation

enum UserRole: String, Codable {
    case child
    case mentor
}

/// 권한 구분: ADMIN = 관리자, USER = 일반 회원
enum UserAuthority: String, Codable {
    case admin = "ADMIN"
    case user = "USER"
}

/// 계정 상태
enum AccountStatus: String, Codable {
    case active = "ACTIVE"                     // 정상
    case deletionPending = "DELETION_PENDING"  // 탈퇴 신청 후 3일 유예 중 (로그인 시 복구 가능)
    case deleted = "DELETED"                   // 영구 삭제 (저장소에서 제거됨)
}

/// 회원 유형: 역할(자녀/멘토)과 권한(관리자)을 합쳐 하나로 구분
enum MemberType: String {
    case child = "CHILD"
    case mentor = "MENTOR"
    case admin = "ADMIN"

    var label: String {
        switch self {
        case .child:  return "자녀"
        case .mentor: return "멘토"
        case .admin:  return "관리자"
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "남성"
    case female = "여성"
}

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var username: String
    var email: String
    /// PasswordHasher 형식의 해시. 평문 비밀번호는 저장하지 않는다.
    var passwordHash: String
    var phone: String
    var role: UserRole
    var authority: UserAuthority
    var birthDate: Date
    var gender: Gender
    var profileImageData: Data?
    var university: String?
    /// 가입일 (이전 버전에서 가입한 회원은 nil)
    var createdAt: Date?
    var accountStatus: AccountStatus = .active
    /// 탈퇴 신청 시각
    var deletionRequestedAt: Date?
    /// 영구 삭제 예정 시각 (탈퇴 신청 + 3일)
    var scheduledDeletionAt: Date?

    var isAdmin: Bool { authority == .admin }
    var isActive: Bool { accountStatus == .active }
    var isPendingDeletion: Bool { accountStatus == .deletionPending }
    var memberType: MemberType {
        if isAdmin { return .admin }
        return role == .mentor ? .mentor : .child
    }

    /// 유예기간이 끝나 영구 삭제 대상인지
    func isPastDeletionDate(now: Date = Date()) -> Bool {
        guard isPendingDeletion else { return accountStatus == .deleted }
        guard let scheduledDeletionAt else { return true }
        return scheduledDeletionAt <= now
    }

    init(name: String, username: String, email: String, password: String, phone: String,
         role: UserRole, birthDate: Date, gender: Gender, profileImageData: Data? = nil,
         university: String? = nil) {
        self.init(name: name, username: username, email: email,
                  passwordHash: PasswordHasher.hash(password), phone: phone,
                  role: role, authority: .user, birthDate: birthDate, gender: gender,
                  profileImageData: profileImageData, university: university)
    }

    init(id: UUID = UUID(), name: String, username: String, email: String, passwordHash: String,
         phone: String, role: UserRole, authority: UserAuthority, birthDate: Date, gender: Gender,
         profileImageData: Data? = nil, university: String? = nil, createdAt: Date? = Date()) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.phone = phone
        self.role = role
        self.authority = authority
        self.birthDate = birthDate
        self.gender = gender
        self.profileImageData = profileImageData
        self.university = university
        self.createdAt = createdAt
    }

    // MARK: - Codable (이전 버전의 평문 password 필드를 해시로 변환)

    private enum CodingKeys: String, CodingKey {
        case id, name, username, email, passwordHash, phone, role, authority
        case birthDate, gender, profileImageData, university, createdAt
        case accountStatus, deletionRequestedAt, scheduledDeletionAt
        case legacyPassword = "password"
        case legacyWithdrawnAt = "withdrawnAt"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        username = try c.decode(String.self, forKey: .username)
        email = try c.decode(String.self, forKey: .email)
        phone = try c.decode(String.self, forKey: .phone)
        role = try c.decode(UserRole.self, forKey: .role)
        authority = try c.decodeIfPresent(UserAuthority.self, forKey: .authority) ?? .user
        birthDate = try c.decode(Date.self, forKey: .birthDate)
        gender = try c.decode(Gender.self, forKey: .gender)
        profileImageData = try c.decodeIfPresent(Data.self, forKey: .profileImageData)
        university = try c.decodeIfPresent(String.self, forKey: .university)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        deletionRequestedAt = try c.decodeIfPresent(Date.self, forKey: .deletionRequestedAt)
        scheduledDeletionAt = try c.decodeIfPresent(Date.self, forKey: .scheduledDeletionAt)
        if let status = try c.decodeIfPresent(AccountStatus.self, forKey: .accountStatus) {
            accountStatus = status
        } else if try c.decodeIfPresent(Date.self, forKey: .legacyWithdrawnAt) != nil {
            // 이전 버전에서 즉시 탈퇴 처리된 계정은 이미 개인정보가 지워져 복구할 수 없으므로 삭제 대상
            accountStatus = .deleted
        } else {
            accountStatus = .active
        }
        if let hash = try c.decodeIfPresent(String.self, forKey: .passwordHash) {
            passwordHash = hash
        } else if let legacy = try c.decodeIfPresent(String.self, forKey: .legacyPassword) {
            passwordHash = PasswordHasher.hash(legacy)
        } else {
            passwordHash = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(username, forKey: .username)
        try c.encode(email, forKey: .email)
        try c.encode(passwordHash, forKey: .passwordHash)
        try c.encode(phone, forKey: .phone)
        try c.encode(role, forKey: .role)
        try c.encode(authority, forKey: .authority)
        try c.encode(birthDate, forKey: .birthDate)
        try c.encode(gender, forKey: .gender)
        try c.encodeIfPresent(profileImageData, forKey: .profileImageData)
        try c.encodeIfPresent(university, forKey: .university)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encode(accountStatus, forKey: .accountStatus)
        try c.encodeIfPresent(deletionRequestedAt, forKey: .deletionRequestedAt)
        try c.encodeIfPresent(scheduledDeletionAt, forKey: .scheduledDeletionAt)
    }
}
