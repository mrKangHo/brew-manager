import Foundation

protocol BrewCatalogRepositoryProtocol: Sendable {
    func fetchCatalog() async -> (formulae: [BrewPackage], casks: [BrewPackage], isCachedOrFetched: Bool)
}
