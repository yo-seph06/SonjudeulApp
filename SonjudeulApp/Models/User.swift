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
    /// 탈퇴일. 값이 있으면 탈퇴(비활성) 회원
    var withdrawnAt: Date?

    var isAdmin: Bool { authority == .admin }
    var isActive: Bool { withdrawnAt == nil }

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
        case birthDate, gender, profileImageData, university, createdAt, withdrawnAt
        case legacyPassword = "password"
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
        withdrawnAt = try c.decodeIfPresent(Date.self, forKey: .withdrawnAt)
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
        try c.encodeIfPresent(withdrawnAt, forKey: .withdrawnAt)
    }
}
