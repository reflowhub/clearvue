import Foundation

enum AppPhase {
    case intro
    case deviceInfo
    case testing
    case results
}

@MainActor
class TestRunner: ObservableObject {
    @Published var phase: AppPhase = .intro
    @Published var currentIndex: Int = 0
    @Published var results: [TestID: TestResult] = [:]
    @Published var imei: String?

    let tests = TestDefinition.allTests
    private var startTime: Date = Date()

    var currentTest: TestDefinition? {
        guard currentIndex < tests.count else { return nil }
        return tests[currentIndex]
    }

    var progressPercent: Double {
        guard !tests.isEmpty else { return 0 }
        return Double(currentIndex) / Double(tests.count)
    }

    func showDeviceInfo() {
        phase = .deviceInfo
    }

    func start() {
        currentIndex = 0
        results = [:]
        startTime = Date()
        phase = .testing
    }

    func record(_ testID: TestID, status: TestStatus, detail: String? = nil) {
        let test = tests.first { $0.id == testID }!
        results[testID] = TestResult(
            testID: testID,
            status: status,
            verification: test.verification,
            detail: detail,
            timestamp: Date()
        )
        currentIndex += 1
        if currentIndex >= tests.count {
            phase = .results
        }
    }

    func restart() {
        start()
    }

    func buildReport() -> DiagnosticReport {
        let orderedResults = tests.compactMap { results[$0.id] }
        return DiagnosticReport(
            id: DiagnosticReport.generateID(),
            results: orderedResults,
            startedAt: startTime,
            completedAt: Date(),
            deviceModel: DiagnosticReport.currentDeviceModel,
            iosVersion: DiagnosticReport.currentIOSVersion,
            imei: imei,
            storageTotal: DiagnosticReport.currentStorageTotal,
            storageAvailable: DiagnosticReport.currentStorageAvailable,
            batteryHealth: DiagnosticReport.currentBatteryHealth,
            batteryLevel: DiagnosticReport.currentBatteryLevel
        )
    }
}
