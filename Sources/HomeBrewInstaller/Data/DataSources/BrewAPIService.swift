import Foundation

final class BrewAPIService: @unchecked Sendable {
    static let shared = BrewAPIService()

    private let formulaURL = URL(string: "https://formulae.brew.sh/api/formula.json")!
    private let caskURL = URL(string: "https://formulae.brew.sh/api/cask.json")!
    private let maxCacheAge: TimeInterval = 24 * 3600

    private var cacheDir: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("HomeBrewInstaller", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var formulaCachePath: URL { cacheDir.appendingPathComponent("formula.json") }
    private var caskCachePath: URL { cacheDir.appendingPathComponent("cask.json") }

    func fetchCatalog() async -> (formulae: [BrewPackage], casks: [BrewPackage], isCachedOrFetched: Bool) {
        async let f = loadOne(url: formulaURL, cachePath: formulaCachePath)
        async let c = loadOne(url: caskURL, cachePath: caskCachePath)
        let (formulaData, caskData) = await (f, c)

        async let df = decodeFormulaeAsync(formulaData)
        async let dc = decodeCasksAsync(caskData)
        let formulae = await df
        let casks = await dc

        let success = (formulaData != nil || caskData != nil)
        return (formulae, casks, success)
    }

    private func loadOne(url: URL, cachePath: URL) async -> Data? {
        if let attrs = try? FileManager.default.attributesOfItem(atPath: cachePath.path),
           let modDate = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) < maxCacheAge,
           let cached = try? Data(contentsOf: cachePath) {
            return cached
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try? data.write(to: cachePath, options: .atomic)
            return data
        } catch {
            return try? Data(contentsOf: cachePath)
        }
    }

    private struct FormulaEntry: Decodable {
        let name: String
        let desc: String?
        let homepage: String?
    }

    private struct CaskEntry: Decodable {
        let token: String
        let name: [String]?
        let desc: String?
        let homepage: String?
    }

    private func decodeFormulaeAsync(_ data: Data?) async -> [BrewPackage] {
        guard let data else { return [] }
        return await Task.detached(priority: .userInitiated) {
            guard let entries = try? JSONDecoder().decode([FormulaEntry].self, from: data) else { return [] }
            return entries.map {
                BrewPackage(name: $0.name, displayName: $0.name, desc: $0.desc ?? "", kind: .formula, homepage: $0.homepage)
            }
        }.value
    }

    private func decodeCasksAsync(_ data: Data?) async -> [BrewPackage] {
        guard let data else { return [] }
        return await Task.detached(priority: .userInitiated) {
            guard let entries = try? JSONDecoder().decode([CaskEntry].self, from: data) else { return [] }
            return entries.map {
                BrewPackage(name: $0.token, displayName: $0.name?.first ?? $0.token, desc: $0.desc ?? "", kind: .cask, homepage: $0.homepage)
            }
        }.value
    }
}
