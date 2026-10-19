import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var selectedRole: UserRole = .child
    @Published var hasCompletedOnboarding: Bool = false

    private let store: UserStore
    private let session: SessionStoring
    /// 현재 시각 (테스트에서 시간 경과를 흉내 내기 위해 주입 가능)
    private let now: () -> Date

    /// 관리자 여부는 화면 상태가 아니라 저장소의 회원 권한으로 판단한다.
    var isAdmin: Bool { store.isAdmin(currentUser?.id) }
    /// 기본 관리자 비밀번호를 아직 바꾸지 않은 관리자 (관리자 기능 사용 전 변경 필요)
    var mustChangeAdminPassword: Bool { store.requiresAdminPasswordChange(currentUser?.id) }

    init(store: UserStore = .shared, session: SessionStoring = KeychainSessionStore(),
         now: @escaping () -> Date = Date.init) {
        self.store = store
        self.session = session
        self.now = now
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        migrateLegacySession()
        restoreSession()
    }

    enum LoginResult: Equatable {
        case success
        case wrongCredentials
        case wrongRole
        /// 탈퇴 유예 중인 계정: 로그인하지 않고 복구 여부를 묻는다
        case pendingDeletion(requestedAt: Date, scheduledDeletionAt: Date)
    }

    @discardableResult
    func login(identifier: String, password: String, role: UserRole) -> LoginResult {
        guard let user = store.verifyCredentials(identifier: identifier, password: password, now: now()) else {
            return .wrongCredentials
        }
        // 관리자는 어느 로그인 화면에서든 로그인 가능
        guard user.isAdmin || user.role == role else {
            return .wrongRole
        }
        if user.isPendingDeletion {
            let requested = user.deletionRequestedAt ?? now()
            return .pendingDeletion(requestedAt: requested,
                                    scheduledDeletionAt: user.scheduledDeletionAt
                                        ?? DeletionPolicy.scheduledDeletionDate(from: requested))
        }
        startSession(for: user)
        return .success
    }

    /// 탈퇴 유예 중인 계정을 복구하고 로그인한다. 아이디·비밀번호를 다시 확인한다.
    @discardableResult
    func restoreAccount(identifier: String, password: String, role: UserRole) -> LoginResult {
        guard let user = store.verifyCredentials(identifier: identifier, password: password, now: now()) else {
            return .wrongCredentials
        }
        guard user.isAdmin || user.role == role else { return .wrongRole }
        guard let restored = try? store.restoreAccount(identifier: identifier, password: password, now: now()) else {
            return .wrongCredentials
        }
        startSession(for: restored)
        return .success
    }

    func logout() {
        AdminReauthSession.shared.invalidate()
        session.clear()
        isLoggedIn = false
        currentUser = nil
        selectedRole = .child
    }

    /// 로그인한 본인의 프로필만 수정할 수 있다. 전화번호 형식·중복 오류는 그대로 전달한다.
    func updateCurrentUser(_ updated: User) throws {
        guard let current = currentUser, current.id == updated.id else { throw AccountError.notAuthorized }
        currentUser = try store.updateProfile(updated)
    }

    func changePassword(current: String, new newPassword: String) throws {
        guard let id = currentUser?.id else { throw AccountError.notFound }
        try store.changePassword(userId: id, current: current, new: newPassword)
        // 비밀번호가 바뀌면 이전 재인증은 무효로 하고, 관리자 화면이 권한 상태를 다시 읽게 한다
        AdminReauthSession.shared.invalidate()
        objectWillChange.send()
    }

    /// 본인 계정 탈퇴 신청 (3일 유예). 계정은 즉시 비활성화되고 저장된 로그인 상태도 지운다.
    /// 화면에서 신청 결과(신청일·삭제 예정일)를 보여준 뒤 logout()을 호출한다.
    @discardableResult
    func requestDeletion(password: String) throws -> User {
        guard let id = currentUser?.id else { throw AccountError.notFound }
        let pending = try store.requestDeletion(userId: id, requestedBy: id, password: password, now: now())
        session.clear()
        currentUser = pending
        return pending
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
