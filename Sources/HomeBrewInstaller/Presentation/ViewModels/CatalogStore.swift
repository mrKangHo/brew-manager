import Foundation

@MainActor
final class CatalogStore: ObservableObject {
    @Published var formulae: [BrewPackage] = []
    @Published var casks: [BrewPackage] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private let fetchCatalogUseCase: FetchCatalogUseCaseProtocol
    private let filterPackagesUseCase: FilterPackagesUseCaseProtocol

    init(
        fetchCatalogUseCase: FetchCatalogUseCaseProtocol = AppDIContainer.shared.fetchCatalogUseCase,
        filterPackagesUseCase: FilterPackagesUseCaseProtocol = AppDIContainer.shared.filterPackagesUseCase
    ) {
        self.fetchCatalogUseCase = fetchCatalogUseCase
        self.filterPackagesUseCase = filterPackagesUseCase
    }

    func load() async {
        guard formulae.isEmpty && casks.isEmpty else { return }
        isLoading = true
        let result = await fetchCatalogUseCase.execute()
        isLoading = false
        formulae = result.formulae
        casks = result.casks

        if !result.success && formulae.isEmpty && casks.isEmpty {
            loadError = L("목록을 불러오지 못했습니다. 네트워크 연결을 확인해 주세요.")
        }
    }

    func filter(packages: [BrewPackage], query: String, category: PackageCategory?) -> [BrewPackage] {
        filterPackagesUseCase.filter(packages: packages, query: query, category: category)
    }
}
