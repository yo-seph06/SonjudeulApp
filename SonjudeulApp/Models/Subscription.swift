import Foundation

struct Subscription: Identifiable {
    let id = UUID()
    var plan: String
    var nextVisit: String
    var nextPayment: String
    var totalVisits: Int
}
