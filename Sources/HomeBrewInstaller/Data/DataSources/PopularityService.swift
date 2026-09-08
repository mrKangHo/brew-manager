import Foundation

struct AnalyticsResponse: Decodable {
    let items: [AnalyticsItem]
}

struct AnalyticsItem: Decodable {
    let number: Int
    let formula: String?
    let cask: String?
    let count: String
}

enum PopularityService {
    static let formulaURL = URL(string: "https://formulae.brew.sh/api/analytics/install-on-request/90d.json")!
    static let caskURL = URL(string: "https://formulae.brew.sh/api/analytics/cask-install/90d.json")!

    static func fetchRanks() async -> [String: Int] {
        async let formulaRanks = fetchOne(formulaURL, key: { $0.formula })
        async let caskRanks = fetchOne(caskURL, key: { $0.cask })
        var result = await formulaRanks
        result.merge(await caskRanks) { a, _ in a }
        return result
    }

    private static func fetchOne(_ url: URL, key: (AnalyticsItem) -> String?) async -> [String: Int] {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(AnalyticsResponse.self, from: data)
            var ranks: [String: Int] = [:]
            for item in decoded.items {
                guard let name = key(item) else { continue }
                ranks[name] = item.number
            }
            return ranks
        } catch {
            return [:]
        }
    }
}
