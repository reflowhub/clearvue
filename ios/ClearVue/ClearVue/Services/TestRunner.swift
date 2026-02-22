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
    @Published var testKey: UUID = UUID()
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

    var canGoBack: Bool {
        currentIndex > 0
    }

    func showDeviceInfo() {
        phase = .deviceInfo
    }

    func start() {
        currentIndex = 0
        results = [:]
        startTime = Date()
        testKey = UUID()
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
        testKey = UUID()
        if currentIndex >= tests.count {
            phase = .results
        }
    }

    func restart() {
        start()
    }

    func goBack() {
        guard canGoBack else { return }
        let previousTest = tests[currentIndex - 1]
        results.removeValue(forKey: previousTest.id)
        currentIndex -= 1
        testKey = UUID()
    }

    func repeatTest() {
        if let test = currentTest {
            results.removeValue(forKey: test.id)
        }
        testKey = UUID()
    }

    func exitTests() {
        phase = .intro
        currentIndex = 0
        results = [:]
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
