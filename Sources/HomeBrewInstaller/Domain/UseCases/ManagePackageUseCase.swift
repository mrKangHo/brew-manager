import Foundation

protocol ManagePackageUseCaseProtocol: Sendable {
    func executeAction(_ action: String, package: BrewPackage, brewPath: String) async -> (output: String, success: Bool, isPermissionError: Bool)
    func upgradeAll(brewPath: String, hasOutdatedFormulae: Bool, hasOutdatedCasks: Bool) async
}

final class ManagePackageUseCase: ManagePackageUseCaseProtocol {
    private let repository: BrewProcessRepositoryProtocol

    init(repository: BrewProcessRepositoryProtocol) {
        self.repository = repository
    }

    func executeAction(_ action: String, package: BrewPackage, brewPath: String) async -> (output: String, success: Bool, isPermissionError: Bool) {
        let result = await repository.runPackageAction(brewPath: brewPath, action: action, package: package)
        return (result.output, result.success, result.isPermissionError)
    }

    func upgradeAll(brewPath: String, hasOutdatedFormulae: Bool, hasOutdatedCasks: Bool) async {
        await repository.runUpgradeAll(brewPath: brewPath, upgradeFormulae: hasOutdatedFormulae, upgradeCasks: hasOutdatedCasks)
    }
}
