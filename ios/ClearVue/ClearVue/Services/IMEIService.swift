import Foundation

struct TACResult: Codable {
    let valid: Bool
    let error: String?
    let tac: String?
    let make: String?
    let model: String?
    let storage: String?

    var deviceLabel: String? {
        guard let make, let model else { return nil }
        if let storage {
            return "\(make) \(model) \(storage)"
        }
        return "\(make) \(model)"
    }
}

enum IMEIService {
    static func lookup(_ imei: String) async throws -> TACResult {
        let url = URL(string: "https://rhex.app/api/imei")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["imei": imei])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TACResult.self, from: data)
    }
}
