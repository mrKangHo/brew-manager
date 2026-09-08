import Foundation

final class AppDIContainer: @unchecked Sendable {
    static let shared = AppDIContainer()

    let brewCLIExecutionService: BrewCLIExecutionService
    let brewAPIService: BrewAPIService

    let brewProcessRepository: BrewProcessRepositoryProtocol
    let brewCatalogRepository: BrewCatalogRepositoryProtocol

    let checkBrewEnvironmentUseCase: CheckBrewEnvironmentUseCaseProtocol
    let managePackageUseCase: ManagePackageUseCaseProtocol
    let fetchCatalogUseCase: FetchCatalogUseCaseProtocol
    let filterPackagesUseCase: FilterPackagesUseCaseProtocol

    private init() {
        let cli = BrewCLIExecutionService.shared
        let api = BrewAPIService.shared

        self.brewCLIExecutionService = cli
        self.brewAPIService = api

        self.brewProcessRepository = BrewProcessRepositoryImpl(cliService: cli)
        self.brewCatalogRepository = BrewCatalogRepositoryImpl(apiService: api)

        self.checkBrewEnvironmentUseCase = CheckBrewEnvironmentUseCase(repository: self.brewProcessRepository)
        self.managePackageUseCase = ManagePackageUseCase(repository: self.brewProcessRepository)
        self.fetchCatalogUseCase = FetchCatalogUseCase(repository: self.brewCatalogRepository)
        self.filterPackagesUseCase = FilterPackagesUseCase()
    }
}
