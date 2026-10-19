import Foundation

/// 중요한 관리자 작업(연결 해제, 방문 일정 변경·삭제) 전에 관리자 비밀번호를 다시 확인한다.
/// - 확인에 성공하면 그 관리자에 한해 5분 동안 유효하다. (메모리에만 보관, 앱을 다시 켜면 다시 확인)
/// - 5번 연속 틀리면 5분 동안 재인증을 막는다.
/// - 비밀번호는 저장하거나 기록하지 않는다.
final class AdminReauthSession {
    static let shared = AdminReauthSession()
    static let validity: TimeInterval = 5 * 60
    static let maxFailures = 5
    static let lockDuration: TimeInterval = 5 * 60

    enum Result: Equatable {
        case success
        case wrongPassword(remainingAttempts: Int)
        case locked(until: Date)
        case notAuthorized
    }

    private let userStore: UserStore
    private let lock = NSLock()
    private var verifiedAdminId: UUID?
    private var verifiedAt: Date?
    private var failures = 0
    private var lockedUntil: Date?

    private init() { userStore = .shared }

    /// 테스트용: 지정한 회원 저장소를 쓰는 독립 세션
    init(userStore: UserStore) { self.userStore = userStore }

    func verify(adminId: UUID?, password: String, now: Date = Date()) -> Result {
        lock.lock(); defer { lock.unlock() }
        guard let adminId, userStore.canUseAdminFeatures(adminId) else { return .notAuthorized }
        if let lockedUntil, lockedUntil > now { return .locked(until: lockedUntil) }

        if userStore.verifyPassword(userId: adminId, password: password) {
            verifiedAdminId = adminId
            verifiedAt = now
            failures = 0
            lockedUntil = nil
            return .success
        }
        failures += 1
        if failures >= Self.maxFailures {
            failures = 0
            let until = now.addingTimeInterval(Self.lockDuration)
            lockedUntil = until
            invalidateLocked()
            return .locked(until: until)
        }
        return .wrongPassword(remainingAttempts: Self.maxFailures - failures)
    }

    /// 최근 5분 안에 같은 관리자가 재인증했는지 (권한도 저장소 기준으로 다시 확인)
    func isFresh(for adminId: UUID?, now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard let adminId, adminId == verifiedAdminId, let verifiedAt,
              userStore.canUseAdminFeatures(adminId) else { return false }
        return now.timeIntervalSince(verifiedAt) < Self.validity && now >= verifiedAt
    }

    func invalidate() {
        lock.lock(); defer { lock.unlock() }
        invalidateLocked()
    }

    private func invalidateLocked() {
        verifiedAdminId = nil
        verifiedAt = nil
    }
}
