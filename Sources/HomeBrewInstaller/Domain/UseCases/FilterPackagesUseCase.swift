import Foundation

protocol FilterPackagesUseCaseProtocol: Sendable {
    func filter(packages: [BrewPackage], query: String, category: PackageCategory?) -> [BrewPackage]
}

final class FilterPackagesUseCase: FilterPackagesUseCaseProtocol {
    init() {}

    func filter(packages: [BrewPackage], query: String, category: PackageCategory?) -> [BrewPackage] {
        var result = packages
        if let cat = category, cat != .other {
            result = result.filter { PackageCategory.categorize($0) == cat }
        }

        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !cleanQuery.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(cleanQuery) ||
                $0.displayName.lowercased().contains(cleanQuery) ||
                $0.desc.lowercased().contains(cleanQuery)
            }
        }
        return result
    }
}
