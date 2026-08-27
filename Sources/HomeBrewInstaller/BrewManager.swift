import Foundation
import Combine
import AppKit

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
    @Published var showPermissionsGuide: Bool = false
    /// macOS has no public API to preflight "App Management" or "Automation"
    /// TCC status, so this isn't a live check — it's inferred: once a cask
    /// install/uninstall/upgrade has actually succeeded, both permissions
    /// must already be in working order (Homebrew would have hit a
    /// permission error otherwise, surfaced separately via `.permissionNeeded`).
    @Published var caskPermissionsConfirmed: Bool = UserDefaults.standard.bool(forKey: BrewManager.caskPermissionsConfirmedKey)

    static let candidatePaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
    private static let appManagementSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AppManagement")!
    private static let automationSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
    private static let permissionsGuideShownKey = "hasShownPermissionsGuide"
    private static let caskPermissionsConfirmedKey = "hasConfirmedCaskPermissions"

    /// Shown once ever, unless a successful cask operation has already
    /// confirmed the permissions are working. Reachable again anytime via
    /// `presentPermissionsGuide()`.
    func maybeShowPermissionsGuide() {
        guard isBrewInstalled, !caskPermissionsConfirmed,
              !UserDefaults.standard.bool(forKey: Self.permissionsGuideShownKey) else { return }
        showPermissionsGuide = true
    }

    func presentPermissionsGuide() {
        showPermissionsGuide = true
    }

    func dismissPermissionsGuide() {
        showPermissionsGuide = false
        UserDefaults.standard.set(true, forKey: Self.permissionsGuideShownKey)
    }

    private func confirmCaskPermissionsIfNeeded(_ pkg: BrewPackage) {
        guard pkg.kind == .cask, !caskPermissionsConfirmed else { return }
        caskPermissionsConfirmed = true
        UserDefaults.standard.set(true, forKey: Self.caskPermissionsConfirmedKey)
    }

    /// There's no API to read the actual toggle in System Settings, so if the
    /// user already granted it there themselves, the only way to reflect that
    /// here is to let them say so directly.
    func confirmPermissionsManually() {
        caskPermissionsConfirmed = true
        UserDefaults.standard.set(true, forKey: Self.caskPermissionsConfirmedKey)
    }

    func openAppManagementSettings() {
        NSWorkspace.shared.open(Self.appManagementSettingsURL)
    }

    func openAutomationSettings() {
        NSWorkspace.shared.open(Self.automationSettingsURL)
    }

    private func isPermissionError(_ output: String) -> Bool {
        let needles = [
            "Operation not permitted", "not permitted to send Apple events",
            "App Management", "Permission denied", "you don't have permission",
        ]
        return needles.contains { output.localizedCaseInsensitiveContains($0) }
    }

    private func isSudoPasswordNeeded(_ output: String) -> Bool {
        let needles = [
            "a password is required", "sudo: a terminal is required", "sudo: no tty present",
        ]
        return needles.contains { output.localizedCaseInsensitiveContains($0) }
    }

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
        var result = await run(brew, args)
        if !result.success && isSudoPasswordNeeded(result.output) {
            states[pkg.id] = .working(L("관리자 암호 필요..."))
            result = await runElevated(brew, args)
        }
        if result.success {
            states[pkg.id] = .installed
            if pkg.kind == .formula { installedFormulae.insert(pkg.name) } else { installedCasks.insert(pkg.name) }
        } else if isPermissionError(result.output) {
            states[pkg.id] = .permissionNeeded(result.output)
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
        var result = await run(brew, args)
        if !result.success && isSudoPasswordNeeded(result.output) {
            states[pkg.id] = .working(L("관리자 암호 필요..."))
            result = await runElevated(brew, args)
        }
        if result.success {
            states[pkg.id] = .notInstalled
            if pkg.kind == .formula { installedFormulae.remove(pkg.name) } else { installedCasks.remove(pkg.name) }
            confirmCaskPermissionsIfNeeded(pkg)
        } else if isPermissionError(result.output) {
            states[pkg.id] = .permissionNeeded(result.output)
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
        var result = await run(brew, args)
        if !result.success && isSudoPasswordNeeded(result.output) {
            states[pkg.id] = .working(L("관리자 암호 필요..."))
            result = await runElevated(brew, args)
        }
        if result.success {
            states[pkg.id] = .installed
            if pkg.kind == .formula { outdatedFormulae.remove(pkg.name) } else { outdatedCasks.remove(pkg.name) }
            confirmCaskPermissionsIfNeeded(pkg)
        } else if isPermissionError(result.output) {
            states[pkg.id] = .permissionNeeded(result.output)
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

    /// Homebrew refuses to run as root, so instead of elevating the whole
    /// `brew` process we hand it a GUI askpass helper. Homebrew's own
    /// internal `sudo` calls (e.g. removing a cask's privileged helper
    /// files) pick this up via the `SUDO_ASKPASS` env var and prompt for
    /// the password through this dialog instead of failing on the missing tty.
    private func makeAskpassScript() -> URL? {
        let prompt = L("Homebrew 작업에 관리자 암호가 필요합니다.")
        let appleScript = "display dialog \"\(prompt)\" default answer \"\" with hidden answer with icon caution"
        let script = """
        #!/bin/sh
        osascript -e '\(appleScript)' -e 'text returned of result'
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("brewmanager-askpass-\(UUID().uuidString).sh")
        do {
            try script.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
            return url
        } catch {
            return nil
        }
    }

    private func runElevated(_ path: String, _ args: [String]) async -> (output: String, success: Bool) {
        guard let askpass = makeAskpassScript() else {
            return (L("관리자 암호 입력창을 준비하지 못했습니다."), false)
        }
        defer { try? FileManager.default.removeItem(at: askpass) }
        return await run(path, args, extraEnv: ["SUDO_ASKPASS": askpass.path])
    }

    @discardableResult
    private func run(_ path: String, _ args: [String], extraEnv: [String: String] = [:]) async -> (output: String, success: Bool) {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args

            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:" + (env["PATH"] ?? "/usr/bin:/bin")
            for (key, value) in extraEnv { env[key] = value }
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
