import Foundation

/// 자녀와의 관계. 기타는 직접 입력한 관계를 저장한다.
enum ParentRelationship: String, CaseIterable, Identifiable {
    case father = "아버지"
    case mother = "어머니"
    case grandfather = "할아버지"
    case grandmother = "할머니"
    case other = "기타"

    var id: String { rawValue }
}

/// 예약 신청 시 저장하는 부모님 기본 정보. 위치는 ParentLocation에 따로 둔다.
struct ParentInfo: Codable, Equatable {
    var name: String
    var age: Int
    var phone: String
    var relationship: String
    var notes: String? = nil
}

/// 부모님 정보 입력·검증 규칙. 화면 안내와 저장 단계(BookingStore) 검증에 함께 쓴다.
enum ParentInfoRule {
    static let ageRange = 30...120
    static let nameMaxLength = 20
    static let relationshipMaxLength = 10
    static let notesMaxLength = 300

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 입력 중 정리

    static func sanitizeName(_ text: String) -> String {
        String(text.prefix(nameMaxLength))
    }

    static func sanitizeAge(_ text: String) -> String {
        String(text.filter { $0.isASCII && $0.isNumber }.prefix(3))
    }

    /// 숫자만 남겨 010-1234-5678 / 011-123-4567 형식으로 하이픈을 넣는다.
    static func formatPhoneInput(_ text: String) -> String {
        let d = Array(text.filter { $0.isASCII && $0.isNumber }.prefix(11))
        switch d.count {
        case 0...3:
            return String(d)
        case 4...7:
            return String(d[0..<3]) + "-" + String(d[3...])
        case 10:
            return String(d[0..<3]) + "-" + String(d[3..<6]) + "-" + String(d[6...])
        default:
            return String(d[0..<3]) + "-" + String(d[3..<7]) + "-" + String(d[7...])
        }
    }

    static func sanitizeRelationship(_ text: String) -> String {
        String(text.prefix(relationshipMaxLength))
    }

    static func sanitizeNotes(_ text: String) -> String {
        String(text.prefix(notesMaxLength))
    }

    // MARK: - 검증 (문제가 없으면 nil)

    static func nameError(_ name: String) -> String? {
        let value = trimmed(name)
        guard !value.isEmpty else { return "부모님 성함을 입력해 주세요." }
        // 한글·영문 등 문자로 시작하고, 이름에 흔히 쓰는 공백·점·하이픈만 허용
        guard value.count <= nameMaxLength,
              value.range(of: "^\\p{L}[\\p{L} .·'-]*$", options: .regularExpression) != nil else {
            return "부모님 성함은 한글 또는 영문으로 입력해 주세요."
        }
        return nil
    }

    static func ageError(_ age: String) -> String? {
        let value = trimmed(age)
        guard !value.isEmpty else { return "부모님 나이를 입력해 주세요." }
        guard value.allSatisfy({ $0.isASCII && $0.isNumber }), let number = Int(value),
              ageRange.contains(number) else {
            return "부모님 나이를 정확히 입력해 주세요. (\(ageRange.lowerBound)~\(ageRange.upperBound)세)"
        }
        return nil
    }

    static func phoneError(_ phone: String) -> String? {
        guard !trimmed(phone).isEmpty else { return "부모님 전화번호를 입력해 주세요." }
        guard PhoneRule.isValid(phone) else { return "올바른 전화번호를 입력해 주세요." }
        return nil
    }

    static func relationshipError(_ relationship: ParentRelationship?, custom: String) -> String? {
        guard let relationship else { return "자녀와의 관계를 선택해 주세요." }
        if relationship == .other {
            let value = trimmed(custom)
            guard !value.isEmpty else { return "관계를 직접 입력해 주세요." }
            guard value.count <= relationshipMaxLength else { return "관계는 \(relationshipMaxLength)자 이내로 입력해 주세요." }
        }
        return nil
    }

    /// 저장 직전 검증. 저장된 값(ParentInfo) 기준으로 같은 규칙을 다시 적용한다.
    static func validate(_ info: ParentInfo) -> String? {
        if let error = nameError(info.name) { return error }
        if let error = ageError(String(info.age)) { return error }
        if let error = phoneError(info.phone) { return error }
        let relationship = trimmed(info.relationship)
        if relationship.isEmpty { return "자녀와의 관계를 선택해 주세요." }
        if relationship.count > relationshipMaxLength { return "관계는 \(relationshipMaxLength)자 이내로 입력해 주세요." }
        if let notes = info.notes, notes.count > notesMaxLength { return "특이사항은 \(notesMaxLength)자 이내로 입력해 주세요." }
        return nil
    }
}
