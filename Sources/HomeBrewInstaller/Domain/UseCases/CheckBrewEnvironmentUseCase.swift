import Foundation

protocol CheckBrewEnvironmentUseCaseProtocol: Sendable {
    func execute() async -> (isInstalled: Bool, brewPath: String?, version: String, installedFormulae: Set<String>, installedCasks: Set<String>, outdatedFormulae: Set<String>, outdatedCasks: Set<String>)
    func installHomebrew() async -> (output: String, success: Bool)
}

final class CheckBrewEnvironmentUseCase: CheckBrewEnvironmentUseCaseProtocol {
    private let repository: BrewProcessRepositoryProtocol

    init(repository: BrewProcessRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async -> (isInstalled: Bool, brewPath: String?, version: String, installedFormulae: Set<String>, installedCasks: Set<String>, outdatedFormulae: Set<String>, outdatedCasks: Set<String>) {
        guard let path = repository.findBrewExecutable() else {
            return (false, nil, "", [], [], [], [])
        }
        let version = await repository.getBrewVersion(brewPath: path)
        async let installed = repository.listInstalled(brewPath: path)
        async let outdated = repository.listOutdated(brewPath: path)

        let (inst, outd) = await (installed, outdated)
        return (true, path, version, inst.formulae, inst.casks, outd.formulae, outd.casks)
    }

    func installHomebrew() async -> (output: String, success: Bool) {
        await repository.installHomebrew()
    }
}
