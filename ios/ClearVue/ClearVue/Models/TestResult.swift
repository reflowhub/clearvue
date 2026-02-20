import Foundation

enum TestStatus: String, Codable {
    case pass
    case fail
    case skipped
    case notTestable = "not_testable"
}

struct TestResult: Codable, Identifiable {
    var id: String { testID.rawValue }
    let testID: TestID
    let status: TestStatus
    let verification: VerificationType
    let detail: String?
    let timestamp: Date
}
