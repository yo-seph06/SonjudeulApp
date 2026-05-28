import Foundation

class UserStore {
    static let shared = UserStore()
    private let key = "registeredUsers"

    private(set) var users: [User] = []

    private init() { load() }

    func register(_ user: User) {
        users.append(user)
        save()
    }

    /// 이메일 또는 아이디 + 비밀번호로 사용자 검색
    func findUser(identifier: String, password: String) -> User? {
        let id = identifier.lowercased()
        return users.first {
            ($0.email.lowercased() == id || $0.username.lowercased() == id)
            && $0.password == password
        }
    }

    func emailExists(_ email: String) -> Bool {
        users.contains { $0.email.lowercased() == email.lowercased() }
    }

    func usernameExists(_ username: String) -> Bool {
        users.contains { $0.username.lowercased() == username.lowercased() }
    }

    func findUserById(_ id: UUID) -> User? {
        users.first { $0.id == id }
    }

    func updateUser(_ updated: User) {
        if let idx = users.firstIndex(where: { $0.id == updated.id }) {
            users[idx] = updated
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([User].self, from: data) else { return }
        users = decoded
    }
}
