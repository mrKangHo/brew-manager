import Foundation

enum PackageKind: String, CaseIterable, Identifiable, Hashable {
    case formula = "Formulae"
    case cask = "Apps (Cask)"
    var id: String { rawValue }
}

struct BrewPackage: Identifiable, Hashable {
    var id: String { "\(kind.rawValue)-\(name)" }
    let name: String
    let displayName: String
    let desc: String
    let kind: PackageKind
    let homepage: String?

    var iconURL: URL? {
        guard let homepage, let host = URL(string: homepage)?.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(host)")
    }
}

enum InstallState: Equatable {
    case notInstalled
    case installed
    case working(String)
    case failed(String)
}
