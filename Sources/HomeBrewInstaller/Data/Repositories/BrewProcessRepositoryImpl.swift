import Foundation

final class BrewProcessRepositoryImpl: BrewProcessRepositoryProtocol {
    private let cliService: BrewCLIExecutionService

    init(cliService: BrewCLIExecutionService = .shared) {
        self.cliService = cliService
    }

    var candidatePaths: [String] {
        BrewCLIExecutionService.candidatePaths
    }

    func findBrewExecutable() -> String? {
        cliService.findExecutable()
    }

    func getBrewVersion(brewPath: String) async -> String {
        let res = await cliService.run(brewPath, ["--version"])
        return res.output.components(separatedBy: "\n").first ?? ""
    }

    func listInstalled(brewPath: String) async -> (formulae: Set<String>, casks: Set<String>) {
        async let f = cliService.run(brewPath, ["list", "--formula"]).output
        async let c = cliService.run(brewPath, ["list", "--cask"]).output
        let (formulaeText, casksText) = await (f, c)
        let formulae = Set(formulaeText.split(separator: "\n").map(String.init))
        let casks = Set(casksText.split(separator: "\n").map(String.init))
        return (formulae, casks)
    }

    func listOutdated(brewPath: String) async -> (formulae: Set<String>, casks: Set<String>) {
        async let f = cliService.run(brewPath, ["outdated", "--formula", "--quiet"]).output
        async let c = cliService.run(brewPath, ["outdated", "--cask", "--quiet"]).output
        let (formulaeText, casksText) = await (f, c)
        let formulae = Set(formulaeText.split(separator: "\n").map(String.init))
        let casks = Set(casksText.split(separator: "\n").map(String.init))
        return (formulae, casks)
    }

    func runPackageAction(brewPath: String, action: String, package: BrewPackage) async -> (output: String, success: Bool, needsSudo: Bool, isPermissionError: Bool) {
        var args = [action]
        if package.kind == .cask { args.append("--cask") }
        args.append(package.name)

        var result = await cliService.run(brewPath, args)
        var needsSudo = false
        if !result.success && cliService.isSudoPasswordNeeded(result.output) {
            needsSudo = true
            result = await cliService.runElevated(brewPath, args)
        }
        let isPerm = cliService.isPermissionError(result.output)
        return (result.output, result.success, needsSudo, isPerm)
    }

    func runUpgradeAll(brewPath: String, upgradeFormulae: Bool, upgradeCasks: Bool) async {
        if upgradeFormulae {
            _ = await cliService.run(brewPath, ["upgrade", "--formula"])
        }
        if upgradeCasks {
            _ = await cliService.run(brewPath, ["upgrade", "--cask"])
        }
    }

    func installHomebrew() async -> (output: String, success: Bool) {
        let script = """
        export NONINTERACTIVE=1
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        """
        let escaped = script
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let osaScript = "do shell script \"\(escaped)\" with administrator privileges"
        return await cliService.run("/usr/bin/osascript", ["-e", osaScript])
    }
}
