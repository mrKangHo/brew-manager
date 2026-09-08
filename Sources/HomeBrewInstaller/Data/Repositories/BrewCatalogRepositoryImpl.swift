import Foundation

final class BrewCatalogRepositoryImpl: BrewCatalogRepositoryProtocol {
    private let apiService: BrewAPIService

    init(apiService: BrewAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchCatalog() async -> (formulae: [BrewPackage], casks: [BrewPackage], isCachedOrFetched: Bool) {
        await apiService.fetchCatalog()
    }
}
