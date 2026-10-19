import Foundation

/// 이메일 입력·검증 규칙. 화면 입력 제한과 저장 단계(UserStore) 검증에 함께 쓴다.
enum EmailRule {
    static let maxLength = 254

    /// 이메일 주소에 쓸 수 있는 문자: 영문, 숫자, @ . 와 RFC 5322 로컬 파트 기호
    private static let allowedSymbols = Set("@.!#$%&'*+-/=?^_`{|}~")

    /// 입력 중 허용되지 않는 문자(한글·공백·기타 기호)를 걸러낸다.
    static func sanitizeInput(_ text: String) -> String {
        String(text.filter { ($0.isASCII && ($0.isLetter || $0.isNumber)) || allowedSymbols.contains($0) }
            .prefix(maxLength))
    }

    /// 중복 비교·저장용: 앞뒤 공백 제거 + 소문자
    static func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// local@domain.tld 형식인지 검사한다. (점으로 시작·끝나거나 연속된 점은 허용하지 않음)
    static func isValid(_ email: String) -> Bool {
        let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= maxLength else { return false }
        let local = "[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
        let label = "[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
        let pattern = "^\(local)@(\(label)\\.)+[A-Za-z]{2,63}$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}

/// 휴대전화 번호 입력·검증 규칙 (한국 휴대전화 번호)
enum PhoneRule {
    /// 입력 중에는 숫자, 하이픈, 공백, 국가번호용 +만 허용한다.
    static func sanitizeInput(_ text: String) -> String {
        String(text.filter { ($0.isASCII && $0.isNumber) || $0 == "-" || $0 == " " || $0 == "+" }.prefix(16))
    }

    /// 중복 비교용: 숫자만 남기고, +82 국가번호는 0으로 바꾼다.
    /// 예) "010-1234-5678", "01012345678", "+82 10-1234-5678" → "01012345678"
    static func normalized(_ phone: String) -> String {
        var digits = phone.filter { $0.isASCII && $0.isNumber }
        if digits.hasPrefix("82"), phone.trimmingCharacters(in: .whitespaces).hasPrefix("+") {
            digits = "0" + digits.dropFirst(2)
        }
        return digits
    }

    /// 010(11자리), 011·016·017·018·019(10~11자리) 휴대전화 번호인지 검사한다.
    static func isValid(_ phone: String) -> Bool {
        normalized(phone).range(of: "^(010[0-9]{8}|01[16789][0-9]{7,8})$", options: .regularExpression) != nil
    }

    /// 저장용 표기: 010-1234-5678 / 011-123-4567
    static func formatted(_ phone: String) -> String {
        let d = Array(normalized(phone))
        guard isValid(phone) else { return phone.trimmingCharacters(in: .whitespaces) }
        let middle = d.count == 11 ? 4 : 3
        return String(d[0..<3]) + "-" + String(d[3..<(3 + middle)]) + "-" + String(d[(3 + middle)...])
    }
}
