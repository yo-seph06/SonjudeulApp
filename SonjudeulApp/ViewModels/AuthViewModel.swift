import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var selectedRole: UserRole = .child
    @Published var hasCompletedOnboarding: Bool = false

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let savedLogin = UserDefaults.standard.bool(forKey: "isLoggedIn")
        if savedLogin,
           let idString = UserDefaults.standard.string(forKey: "currentUserId"),
           let uuid = UUID(uuidString: idString),
           let user = UserStore.shared.findUserById(uuid) {
            currentUser = user
            selectedRole = user.role
            isLoggedIn = true
        }
    }

    enum LoginResult {
        case success
        case wrongCredentials
        case wrongRole
    }

    @discardableResult
    func login(identifier: String, password: String, role: UserRole) -> LoginResult {
        guard let user = UserStore.shared.findUser(identifier: identifier, password: password) else {
            return .wrongCredentials
        }
        guard user.role == role else {
            return .wrongRole
        }
        currentUser = user
        selectedRole = user.role
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(user.id.uuidString, forKey: "currentUserId")
        return .success
    }

    func logout() {
        isLoggedIn = false
        currentUser = nil
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "currentUserId")
    }

    func updateCurrentUser(_ updated: User) {
        UserStore.shared.updateUser(updated)
        currentUser = updated
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
