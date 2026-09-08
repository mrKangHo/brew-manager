import Foundation

protocol BrewProcessRepositoryProtocol: Sendable {
    var candidatePaths: [String] { get }
    func findBrewExecutable() -> String?
    func getBrewVersion(brewPath: String) async -> String
    func listInstalled(brewPath: String) async -> (formulae: Set<String>, casks: Set<String>)
    func listOutdated(brewPath: String) async -> (formulae: Set<String>, casks: Set<String>)
    func runPackageAction(brewPath: String, action: String, package: BrewPackage) async -> (output: String, success: Bool, needsSudo: Bool, isPermissionError: Bool)
    func runUpgradeAll(brewPath: String, upgradeFormulae: Bool, upgradeCasks: Bool) async
    func installHomebrew() async -> (output: String, success: Bool)
}
