import Foundation

class UserStore {
    static let shared = UserStore()
    private let fileName = "sonjudeul_users.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    private(set) var users: [User] = []

    private init() { load() }

    func register(_ user: User) {
        users.append(user)
        save()
    }

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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(users) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([User].self, from: data) else { return }
        users = decoded
    }
}
