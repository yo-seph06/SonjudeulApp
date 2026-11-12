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
    @Published var addressDetail: String = ""
    /// 지도에서 선택한 위치. 주소 입력란(address)은 이 값으로만 채워진다.
    @Published var parentLocation: ParentLocation? = nil
    @Published var visitDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    var planName: String {
        selectedPlan == .subscription ? "안심 정기구독" : "원데이 효도"
    }

    /// 주소가 공백이 아니고, 지도에서 선택한 위도·경도가 있어야 위치 등록이 완료된 것으로 본다.
    var hasValidParentLocation: Bool {
        guard let location = parentLocation, location.isValid else { return false }
        return !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func setParentLocation(_ location: ParentLocation, detail: String) {
        parentLocation = location
        address = location.address
        addressDetail = detail
    }

    func nextStep() {
        switch currentStep {
        case .plan:        currentStep = .bookingInfo
        case .bookingInfo:
            guard hasValidParentLocation else { return }
            currentStep = .complete
        case .complete:    break
        }
    }

    func reset() {
        currentStep = .plan
        parentName = ""
        parentAge = ""
        parentPhone = ""
        address = ""
        addressDetail = ""
        parentLocation = nil
    }
}
