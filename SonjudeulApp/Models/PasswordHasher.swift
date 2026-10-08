import Foundation
import CommonCrypto
import Security

/// 비밀번호를 평문 대신 PBKDF2-SHA256 해시로 저장/검증한다.
/// 저장 형식: "pbkdf2_sha256$<반복횟수>$<salt(base64)>$<hash(base64)>"
enum PasswordHasher {
    private static let algorithm = "pbkdf2_sha256"
    private static let iterations: UInt32 = 120_000
    private static let saltLength = 16
    private static let keyLength = 32

    static func hash(_ password: String) -> String {
        var salt = Data(count: saltLength)
        let status = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, saltLength, $0.baseAddress!)
        }
        precondition(status == errSecSuccess, "salt 생성 실패")
        let derived = derive(password: password, salt: salt, iterations: iterations)
        return "\(algorithm)$\(iterations)$\(salt.base64EncodedString())$\(derived.base64EncodedString())"
    }

    static func verify(_ password: String, against stored: String) -> Bool {
        let parts = stored.split(separator: "$")
        guard parts.count == 4,
              parts[0] == algorithm,
              let rounds = UInt32(parts[1]),
              let salt = Data(base64Encoded: String(parts[2])),
              let expected = Data(base64Encoded: String(parts[3])) else { return false }
        let derived = derive(password: password, salt: salt, iterations: rounds)
        return constantTimeEquals(derived, expected)
    }

    private static func derive(password: String, salt: Data, iterations: UInt32) -> Data {
        let passwordData = Data(password.utf8)
        var derived = Data(count: keyLength)
        let result = derived.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { pwBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pwBytes.baseAddress?.assumingMemoryBound(to: Int8.self), passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self), salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), iterations,
                        derivedBytes.baseAddress?.assumingMemoryBound(to: UInt8.self), keyLength
                    )
                }
            }
        }
        precondition(result == kCCSuccess, "PBKDF2 실패")
        return derived
    }

    private static func constantTimeEquals(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var diff: UInt8 = 0
        for (x, y) in zip(a, b) { diff |= x ^ y }
        return diff == 0
    }
}
