import Foundation

enum TestID: String, CaseIterable, Codable {
    case faceID = "faceid"
    case display = "display"
    case frontCamera = "front_cam"
    case rearCamera = "rear_cam"
    case touchScreen = "touch"
    case microphone = "mic"
    case speaker = "speaker"
    case wifi = "wifi"
    case bluetooth = "bluetooth"
    case cellular = "cellular"
    case gps = "gps"
    case accelerometerGyroscope = "accel_gyro"
    case buttons = "buttons"
}

enum VerificationType: String, Codable {
    case tested = "Tested"
    case selfReported = "Self-reported"
    case untestable = "Untestable"
}

enum TestType {
    case biometric
    case display
    case camera(position: CameraPosition)
    case touch
    case microphone
    case speaker
    case connectivity(subtype: ConnectivitySubtype)
    case bluetooth
    case geolocation
    case motion
    case buttons
}

enum CameraPosition {
    case front, back
}

enum ConnectivitySubtype {
    case wifi, cellular
}

struct TestDefinition: Identifiable {
    let id: TestID
    let name: String
    let description: String
    let type: TestType
    let verification: VerificationType

    static let allTests: [TestDefinition] = [
        TestDefinition(
            id: .faceID,
            name: "Face ID",
            description: "Authenticate with Face ID to verify biometric hardware.",
            type: .biometric,
            verification: .tested
        ),
        TestDefinition(
            id: .display,
            name: "Display Quality",
            description: "Full-screen color panels will appear. Check each for dead pixels, discoloration, or backlight bleed. Tap to advance.",
            type: .display,
            verification: .selfReported
        ),
        TestDefinition(
            id: .frontCamera,
            name: "Front Camera",
            description: "Check that the front camera shows a clear image.",
            type: .camera(position: .front),
            verification: .tested
        ),
        TestDefinition(
            id: .rearCamera,
            name: "Rear Camera",
            description: "Check that the rear camera shows a clear image.",
            type: .camera(position: .back),
            verification: .tested
        ),
        TestDefinition(
            id: .touchScreen,
            name: "Touch Screen",
            description: "Touch every cell in the grid below.",
            type: .touch,
            verification: .tested
        ),
        TestDefinition(
            id: .microphone,
            name: "Microphone",
            description: "A short audio clip will be recorded and played back.",
            type: .microphone,
            verification: .tested
        ),
        TestDefinition(
            id: .speaker,
            name: "Speaker",
            description: "A test tone will play through the speaker.",
            type: .speaker,
            verification: .tested
        ),
        TestDefinition(
            id: .wifi,
            name: "Wi-Fi",
            description: "Testing Wi-Fi connectivity...",
            type: .connectivity(subtype: .wifi),
            verification: .tested
        ),
        TestDefinition(
            id: .bluetooth,
            name: "Bluetooth",
            description: "Checking Bluetooth radio status...",
            type: .bluetooth,
            verification: .tested
        ),
        TestDefinition(
            id: .cellular,
            name: "Cellular Signal",
            description: "Checking cellular connectivity...",
            type: .connectivity(subtype: .cellular),
            verification: .tested
        ),
        TestDefinition(
            id: .gps,
            name: "GPS / Location",
            description: "Requesting location to verify GPS hardware...",
            type: .geolocation,
            verification: .tested
        ),
        TestDefinition(
            id: .accelerometerGyroscope,
            name: "Accelerometer / Gyroscope",
            description: "Tilt and rotate your device in all directions.",
            type: .motion,
            verification: .tested
        ),
        TestDefinition(
            id: .buttons,
            name: "Physical Buttons",
            description: "Test each physical button when prompted.",
            type: .buttons,
            verification: .selfReported
        ),
    ]
}
