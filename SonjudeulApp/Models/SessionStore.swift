import Foundation
import Security

/// 로그인 상태(로그인한 회원의 고유 ID)를 보관한다. 비밀번호는 저장하지 않는다.
protocol SessionStoring {
    func loadUserId() -> UUID?
    func save(userId: UUID)
    func clear()
}

/// 키체인에 로그인 회원 ID만 저장한다 (이 기기에서만, 잠금 해제 후 접근 가능).
struct KeychainSessionStore: SessionStoring {
    private let service = "com.kimnahyun.sonjudeulapp.session"
    private let account = "currentUserId"

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    func loadUserId() -> UUID? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return UUID(uuidString: string)
    }

    func save(userId: UUID) {
        clear()
        var query = baseQuery
        query[kSecValueData as String] = Data(userId.uuidString.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}

/// 테스트용 메모리 세션
final class InMemorySessionStore: SessionStoring {
    private var userId: UUID?
    func loadUserId() -> UUID? { userId }
    func save(userId: UUID) { self.userId = userId }
    func clear() { userId = nil }
}
