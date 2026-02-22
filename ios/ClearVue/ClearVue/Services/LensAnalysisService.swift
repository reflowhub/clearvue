import Foundation

struct LensAnalysisResult {
    let pass: Bool
    let explanation: String
}

class LensAnalysisService {
    private let endpoint = URL(string: "https://clearvue.rhex.app/api/analyze-lens")!

    func analyze(imageData: Data, cameraPosition: String) async throws -> LensAnalysisResult {
        let base64Image = imageData.base64EncodedString()

        let body: [String: Any] = [
            "image": base64Image,
            "camera_position": cameraPosition
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LensAnalysisError.serverError(msg)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pass = json["pass"] as? Bool,
              let explanation = json["explanation"] as? String else {
            throw LensAnalysisError.invalidResponse
        }

        return LensAnalysisResult(pass: pass, explanation: explanation)
    }
}

enum LensAnalysisError: LocalizedError {
    case serverError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .serverError(let msg): return "Analysis failed: \(msg)"
        case .invalidResponse: return "Could not parse analysis result."
        }
    }
}
