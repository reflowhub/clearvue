import UIKit

struct DiagnosticReport: Codable {
    let id: String
    let results: [TestResult]
    let startedAt: Date
    let completedAt: Date
    let deviceModel: String
    let iosVersion: String
    let imei: String?
    let storageTotal: Int64?
    let storageAvailable: Int64?
    let batteryLevel: Int?

    var passCount: Int { results.filter { $0.status == .pass }.count }
    var failCount: Int { results.filter { $0.status == .fail }.count }
    var testedCount: Int { results.filter { $0.status == .pass || $0.status == .fail }.count }
    var skippedCount: Int { results.filter { $0.status == .skipped }.count }
    var notTestableCount: Int { results.filter { $0.status == .notTestable }.count }

    var formattedStorage: String? {
        guard let total = storageTotal else { return nil }
        let gb = Double(total) / 1_000_000_000
        let roundedGB: Int
        if gb > 400 { roundedGB = 512 }
        else if gb > 200 { roundedGB = 256 }
        else if gb > 100 { roundedGB = 128 }
        else if gb > 50 { roundedGB = 64 }
        else { roundedGB = 32 }

        if let avail = storageAvailable {
            let availGB = Double(avail) / 1_000_000_000
            return "\(roundedGB) GB (\(String(format: "%.1f", availGB)) GB free)"
        }
        return "\(roundedGB) GB"
    }

    static var currentStorageTotal: Int64? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        guard let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey]),
              let total = values.volumeTotalCapacity else { return nil }
        return Int64(total)
    }

    static var currentStorageAvailable: Int64? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let avail = values.volumeAvailableCapacityForImportantUsage else { return nil }
        return avail
    }

    static var currentBatteryLevel: Int? {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return nil }
        return Int(level * 100)
    }

    static func generateID() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let datePart = formatter.string(from: Date())
        let randomPart = String(format: "%04X", Int.random(in: 0...0xFFFF))
        return "CVR-\(datePart)-\(randomPart)"
    }

    static var currentDeviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        return mapToDeviceName(identifier: identifier)
    }

    static var currentIOSVersion: String {
        UIDevice.current.systemVersion
    }

    private static func mapToDeviceName(identifier: String) -> String {
        let map: [String: String] = [
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            "iPhone17,5": "iPhone 16e",
        ]
        return map[identifier] ?? identifier
    }
}
