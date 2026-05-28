import Foundation
import SwiftUI

enum BookingStep {
    case plan, bookingInfo, complete
}

enum PlanType {
    case oneDay, subscription
}

class BookingViewModel: ObservableObject {
    @Published var currentStep: BookingStep = .plan
    @Published var selectedPlan: PlanType = .oneDay

    // Booking info
    @Published var parentName: String = ""
    @Published var parentAge: String = ""
    @Published var parentPhone: String = ""
    @Published var address: String = ""
    @Published var visitDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    func nextStep() {
        switch currentStep {
        case .plan:        currentStep = .bookingInfo
        case .bookingInfo: currentStep = .complete
        case .complete:    break
        }
    }

    func reset() {
        currentStep = .plan
        parentName = ""
        parentAge = ""
        parentPhone = ""
        address = ""
    }
}
