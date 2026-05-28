import Foundation

enum UserRole: String, Codable {
    case child
    case mentor
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
    var password: String
    var phone: String
    var role: UserRole
    var birthDate: Date
    var gender: Gender
    var profileImageData: Data?
    var university: String?

    init(name: String, username: String, email: String, password: String, phone: String,
         role: UserRole, birthDate: Date, gender: Gender, profileImageData: Data? = nil,
         university: String? = nil) {
        self.id = UUID()
        self.name = name
        self.username = username
        self.email = email
        self.password = password
        self.phone = phone
        self.role = role
        self.birthDate = birthDate
        self.gender = gender
        self.profileImageData = profileImageData
        self.university = university
    }
}
