import LocalAuthentication

class FaceIDService {
    enum BiometricResult {
        case success
        case failed(String)
        case unavailable(String)
    }

    func authenticate() async -> BiometricResult {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .unavailable(error?.localizedDescription ?? "Biometrics not available on this device")
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "ClearVue needs to verify Face ID hardware"
            )
            return success ? .success : .failed("Authentication was not successful")
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
