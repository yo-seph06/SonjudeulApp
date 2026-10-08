import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var selectedRole: UserRole = .child
    @Published var hasCompletedOnboarding: Bool = false

    private let store: UserStore
    private let session: SessionStoring

    /// 관리자 여부는 화면 상태가 아니라 저장소의 회원 권한으로 판단한다.
    var isAdmin: Bool { store.isAdmin(currentUser?.id) }

    init(store: UserStore = .shared, session: SessionStoring = KeychainSessionStore()) {
        self.store = store
        self.session = session
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        migrateLegacySession()
        restoreSession()
    }

    enum LoginResult {
        case success
        case wrongCredentials
        case wrongRole
    }

    @discardableResult
    func login(identifier: String, password: String, role: UserRole) -> LoginResult {
        guard let user = store.authenticate(identifier: identifier, password: password) else {
            return .wrongCredentials
        }
        // 관리자는 어느 로그인 화면에서든 로그인 가능
        guard user.isAdmin || user.role == role else {
            return .wrongRole
        }
        startSession(for: user)
        return .success
    }

    func logout() {
        session.clear()
        isLoggedIn = false
        currentUser = nil
        selectedRole = .child
    }

    /// 로그인한 본인의 프로필만 수정할 수 있다.
    func updateCurrentUser(_ updated: User) {
        guard let current = currentUser, current.id == updated.id,
              let saved = store.updateProfile(updated) else { return }
        currentUser = saved
    }

    func changePassword(current: String, new newPassword: String) throws {
        guard let id = currentUser?.id else { throw AccountError.notFound }
        try store.changePassword(userId: id, current: current, new: newPassword)
    }

    /// 본인 계정 탈퇴. 성공하면 탈퇴한 회원 ID를 돌려주고 로그아웃한다.
    @discardableResult
    func withdraw(password: String) throws -> UUID {
        guard let id = currentUser?.id else { throw AccountError.notFound }
        try store.withdraw(userId: id, requestedBy: id, password: password)
        logout()
        return id
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    // MARK: - Session

    private func startSession(for user: User) {
        currentUser = user
        selectedRole = user.role
        isLoggedIn = true
        session.save(userId: user.id)
    }

    /// 저장된 회원 ID로 로그인 상태를 복원한다. 회원이 없거나 탈퇴했으면 세션을 지운다.
    private func restoreSession() {
        guard let id = session.loadUserId() else { return }
        if let user = store.findUserById(id) {
            startSession(for: user)
        } else {
            session.clear()
        }
    }

    /// 이전 버전이 UserDefaults에 저장한 로그인 정보를 키체인으로 옮긴다.
    private func migrateLegacySession() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "isLoggedIn") != nil
                || defaults.object(forKey: "currentUserId") != nil else { return }
        if defaults.bool(forKey: "isLoggedIn"),
           let idString = defaults.string(forKey: "currentUserId"),
           let id = UUID(uuidString: idString) {
            session.save(userId: id)
        }
        defaults.removeObject(forKey: "isLoggedIn")
        defaults.removeObject(forKey: "currentUserId")
    }
}
