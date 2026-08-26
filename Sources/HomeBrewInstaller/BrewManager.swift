import Foundation
import Combine

@MainActor
final class BrewManager: ObservableObject {
    @Published var isBrewInstalled: Bool = false
    @Published var brewVersion: String = ""
    @Published var installedFormulae: Set<String> = []
    @Published var installedCasks: Set<String> = []
    @Published var outdatedFormulae: Set<String> = []
    @Published var outdatedCasks: Set<String> = []
    @Published var states: [String: InstallState] = [:]
    @Published var isInstallingBrew: Bool = false
    @Published var brewInstallLog: String = ""
    @Published var isUpdatingAll: Bool = false

    static let candidatePaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]

    var brewExecutable: String? {
        for path in Self.candidatePaths where FileManager.default.fileExists(atPath: path) {
            return path
        }
        return nil
    }

    func refreshStatus() async {
        guard let brew = brewExecutable else {
            isBrewInstalled = false
            return
        }
        isBrewInstalled = true
        brewVersion = await run(brew, ["--version"]).output.components(separatedBy: "\n").first ?? ""
        async let formulae = run(brew, ["list", "--formula"]).output
        async let casks = run(brew, ["list", "--cask"]).output
        async let outdatedF = run(brew, ["outdated", "--formula", "--quiet"]).output
        async let outdatedC = run(brew, ["outdated", "--cask", "--quiet"]).output
        installedFormulae = Set(await formulae.split(separator: "\n").map(String.init))
        installedCasks = Set(await casks.split(separator: "\n").map(String.init))
        outdatedFormulae = Set(await outdatedF.split(separator: "\n").map(String.init))
        outdatedCasks = Set(await outdatedC.split(separator: "\n").map(String.init))
    }

    func state(for pkg: BrewPackage) -> InstallState {
        if let s = states[pkg.id] { return s }
        let installed = pkg.kind == .formula ? installedFormulae.contains(pkg.name) : installedCasks.contains(pkg.name)
        return installed ? .installed : .notInstalled
    }

    func isOutdated(_ pkg: BrewPackage) -> Bool {
        pkg.kind == .formula ? outdatedFormulae.contains(pkg.name) : outdatedCasks.contains(pkg.name)
    }

    var outdatedCount: Int { outdatedFormulae.count + outdatedCasks.count }

    func install(_ pkg: BrewPackage) async {
        guard let brew = brewExecutable else { return }
        states[pkg.id] = .working(L("설치 중..."))
        var args = ["install"]
        if pkg.kind == .cask { args.append("--cask") }
        args.append(pkg.name)
        let result = await run(brew, args)
        if result.success {
            states[pkg.id] = .installed
            if pkg.kind == .formula { installedFormulae.insert(pkg.name) } else { installedCasks.insert(pkg.name) }
        } else {
            states[pkg.id] = .failed(result.output)
        }
    }

    func uninstall(_ pkg: BrewPackage) async {
        guard let brew = brewExecutable else { return }
        states[pkg.id] = .working(L("삭제 중..."))
        var args = ["uninstall"]
        if pkg.kind == .cask { args.append("--cask") }
        args.append(pkg.name)
        let result = await run(brew, args)
        if result.success {
            states[pkg.id] = .notInstalled
            if pkg.kind == .formula { installedFormulae.remove(pkg.name) } else { installedCasks.remove(pkg.name) }
        } else {
            states[pkg.id] = .failed(result.output)
        }
    }

    func update(_ pkg: BrewPackage) async {
        guard let brew = brewExecutable else { return }
        states[pkg.id] = .working(L("업데이트 중..."))
        var args = ["upgrade"]
        if pkg.kind == .cask { args.append("--cask") }
        args.append(pkg.name)
        let result = await run(brew, args)
        if result.success {
            states[pkg.id] = .installed
            if pkg.kind == .formula { outdatedFormulae.remove(pkg.name) } else { outdatedCasks.remove(pkg.name) }
        } else {
            states[pkg.id] = .failed(result.output)
        }
    }

    func updateAll() async {
        guard let brew = brewExecutable else { return }
        isUpdatingAll = true
        if !outdatedFormulae.isEmpty {
            await run(brew, ["upgrade", "--formula"])
        }
        if !outdatedCasks.isEmpty {
            await run(brew, ["upgrade", "--cask"])
        }
        isUpdatingAll = false
        await refreshStatus()
    }

    func installHomebrew() async {
        isInstallingBrew = true
        brewInstallLog = L("Homebrew 설치를 시작합니다. 관리자 암호를 입력해 주세요...\n")
        let script = """
        export NONINTERACTIVE=1
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        """
        let escaped = script
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let osaScript = "do shell script \"\(escaped)\" with administrator privileges"

        let result = await run("/usr/bin/osascript", ["-e", osaScript])
        brewInstallLog += result.output
        isInstallingBrew = false
        await refreshStatus()
    }

    @discardableResult
    private func run(_ path: String, _ args: [String]) async -> (output: String, success: Bool) {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args

            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:" + (env["PATH"] ?? "/usr/bin:/bin")
            process.environment = env

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { proc in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: (output, proc.terminationStatus == 0))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: ("실행 실패: \(error.localizedDescription)", false))
            }
        }
    }
}
