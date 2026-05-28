import Foundation

struct Mentor: Identifiable {
    let id = UUID()
    var name: String
    var university: String
    var rating: Double
    var reviewCount: Int
    var badges: [String]
}
