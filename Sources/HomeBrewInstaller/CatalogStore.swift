import Foundation

@MainActor
final class CatalogStore: ObservableObject {
    @Published var formulae: [BrewPackage] = []
    @Published var casks: [BrewPackage] = []
    @Published var isLoading = false
    @Published var loadError: String?

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

    func load() async {
        guard formulae.isEmpty && casks.isEmpty else { return }
        isLoading = true
        async let f = loadOne(url: formulaURL, cachePath: formulaCachePath)
        async let c = loadOne(url: caskURL, cachePath: caskCachePath)
        let (formulaData, caskData) = await (f, c)
        isLoading = false

        async let df = Self.decodeFormulaeAsync(formulaData)
        async let dc = Self.decodeCasksAsync(caskData)
        formulae = await df
        casks = await dc
        if formulaData == nil && caskData == nil {
            loadError = L("목록을 불러오지 못했습니다. 네트워크 연결을 확인해 주세요.")
        }
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

    private nonisolated static func decodeFormulaeAsync(_ data: Data?) async -> [BrewPackage] {
        guard let data else { return [] }
        return await Task.detached(priority: .userInitiated) { decodeFormulae(data) }.value
    }

    private nonisolated static func decodeCasksAsync(_ data: Data?) async -> [BrewPackage] {
        guard let data else { return [] }
        return await Task.detached(priority: .userInitiated) { decodeCasks(data) }.value
    }

    private nonisolated static func decodeFormulae(_ data: Data) -> [BrewPackage] {
        guard let entries = try? JSONDecoder().decode([FormulaEntry].self, from: data) else { return [] }
        return entries.map {
            BrewPackage(name: $0.name, displayName: $0.name, desc: $0.desc ?? "", kind: .formula, homepage: $0.homepage)
        }
    }

    private nonisolated static func decodeCasks(_ data: Data) -> [BrewPackage] {
        guard let entries = try? JSONDecoder().decode([CaskEntry].self, from: data) else { return [] }
        return entries.map {
            BrewPackage(name: $0.token, displayName: $0.name?.first ?? $0.token, desc: $0.desc ?? "", kind: .cask, homepage: $0.homepage)
        }
    }
}
