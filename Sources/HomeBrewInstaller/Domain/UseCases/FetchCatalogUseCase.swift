import Foundation

protocol FetchCatalogUseCaseProtocol: Sendable {
    func execute() async -> (formulae: [BrewPackage], casks: [BrewPackage], success: Bool)
}

final class FetchCatalogUseCase: FetchCatalogUseCaseProtocol {
    private let repository: BrewCatalogRepositoryProtocol

    init(repository: BrewCatalogRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async -> (formulae: [BrewPackage], casks: [BrewPackage], success: Bool) {
        let res = await repository.fetchCatalog()
        return (res.formulae, res.casks, res.isCachedOrFetched)
    }
}
