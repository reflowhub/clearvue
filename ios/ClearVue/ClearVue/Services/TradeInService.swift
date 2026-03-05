import Foundation

struct TradeInOffer: Codable {
    let model: String
    let storage: String
    let priceA: Int
    let priceC: Int?
    let currency: String
    let sellUrl: String
}

enum TradeInService {
    static func lookup(model: String, storage: String) async throws -> TradeInOffer {
        var components = URLComponents(string: "https://rhex.app/api/tradein-price")!
        components.queryItems = [
            URLQueryItem(name: "model", value: model),
            URLQueryItem(name: "storage", value: storage),
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(TradeInOffer.self, from: data)
    }
}
