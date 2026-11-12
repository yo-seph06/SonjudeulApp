import Foundation
import SwiftUI

enum BookingStep {
    case plan, bookingInfo, subjects, complete
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
    @Published var relationship: ParentRelationship? = nil
    @Published var customRelationship: String = ""
    @Published var parentNotes: String = ""
    @Published var locationConsent: Bool = false
    /// 선택한 과목 ID (중복 없이 선택 순서대로)
    @Published var selectedSubjectIDs: [String] = []
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

    // MARK: - 부모님 정보 검증 (문제가 없으면 nil)

    var nameError: String? { ParentInfoRule.nameError(parentName) }
    var ageError: String? { ParentInfoRule.ageError(parentAge) }
    var phoneError: String? { ParentInfoRule.phoneError(parentPhone) }
    var relationshipError: String? { ParentInfoRule.relationshipError(relationship, custom: customRelationship) }
    var locationError: String? { hasValidParentLocation ? nil : BookingRequestError.missingParentLocation.message }
    var consentError: String? { locationConsent ? nil : BookingRequestError.missingLocationConsent.message }

    private var requiredErrors: [String?] {
        [nameError, ageError, phoneError, relationshipError, locationError, consentError]
    }

    var requiredCount: Int { requiredErrors.count }
    var completedRequiredCount: Int { requiredErrors.filter { $0 == nil }.count }
    var isParentInfoComplete: Bool { completedRequiredCount == requiredCount }

    // MARK: - 수업 과목

    /// 공통 과목 목록 순서대로 정렬한 선택 과목
    var selectedSubjects: [LessonSubject] {
        LessonSubject.all.filter { selectedSubjectIDs.contains($0.id) }
    }

    var subjectError: String? { LessonSubject.validationError(selectedSubjects) }

    func toggleSubject(_ subject: LessonSubject) {
        if let index = selectedSubjectIDs.firstIndex(of: subject.id) {
            selectedSubjectIDs.remove(at: index)
        } else if LessonSubject.find(id: subject.id) != nil {
            selectedSubjectIDs.append(subject.id)
        }
    }

    /// 필수 항목이 모두 올바를 때만 저장용 부모님 정보를 만든다.
    func makeParentInfo() -> ParentInfo? {
        guard isParentInfoComplete, let relationship, let age = Int(ParentInfoRule.trimmed(parentAge)) else { return nil }
        let notes = ParentInfoRule.trimmed(parentNotes)
        return ParentInfo(
            name: ParentInfoRule.trimmed(parentName),
            age: age,
            phone: PhoneRule.formatted(parentPhone),
            relationship: relationship == .other ? ParentInfoRule.trimmed(customRelationship) : relationship.rawValue,
            notes: notes.isEmpty ? nil : notes
        )
    }

    /// 이전에 신청한 부모님 정보가 있으면, 아직 아무것도 입력하지 않은 경우에만 불러온다.
    /// (위치 수집·제공 동의는 신청마다 다시 받는다)
    func prefill(from record: BookingRecord) {
        guard parentName.isEmpty, parentAge.isEmpty, parentPhone.isEmpty, relationship == nil,
              parentLocation == nil, let info = record.parentInfo else { return }
        parentName = info.name
        parentAge = String(info.age)
        parentPhone = info.phone
        if let known = ParentRelationship(rawValue: info.relationship), known != .other {
            relationship = known
        } else {
            relationship = .other
            customRelationship = info.relationship
        }
        parentNotes = info.notes ?? ""
        if let location = record.parentLocation, location.isValid {
            setParentLocation(location, detail: record.parentAddressDetail ?? "")
        }
        if selectedSubjectIDs.isEmpty, let subjects = record.subjects {
            selectedSubjectIDs = subjects.map(\.id).filter { LessonSubject.find(id: $0) != nil }
        }
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
            guard isParentInfoComplete else { return }
            currentStep = .subjects
        case .subjects:
            guard isParentInfoComplete, subjectError == nil else { return }
            currentStep = .complete
        case .complete:    break
        }
    }

    func reset() {
        currentStep = .plan
        parentName = ""
        parentAge = ""
        parentPhone = ""
        relationship = nil
        customRelationship = ""
        parentNotes = ""
        locationConsent = false
        selectedSubjectIDs = []
        address = ""
        addressDetail = ""
        parentLocation = nil
    }
}
