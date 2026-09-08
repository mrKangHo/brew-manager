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
    @Published var caskPermissionsConfirmed: Bool = UserDefaults.standard.bool(forKey: BrewManager.caskPermissionsConfirmedKey)

    private let checkEnvironmentUseCase: CheckBrewEnvironmentUseCaseProtocol
    private let managePackageUseCase: ManagePackageUseCaseProtocol

    private(set) var brewExecutable: String?

    static let candidatePaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
    private static let appManagementSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AppManagement")!
    private static let automationSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
    private static let permissionsGuideShownKey = "hasShownPermissionsGuide"
    private static let caskPermissionsConfirmedKey = "hasConfirmedCaskPermissions"

    init(
        checkEnvironmentUseCase: CheckBrewEnvironmentUseCaseProtocol = AppDIContainer.shared.checkBrewEnvironmentUseCase,
        managePackageUseCase: ManagePackageUseCaseProtocol = AppDIContainer.shared.managePackageUseCase
    ) {
        self.checkEnvironmentUseCase = checkEnvironmentUseCase
        self.managePackageUseCase = managePackageUseCase
    }

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

    func refreshStatus() async {
        let env = await checkEnvironmentUseCase.execute()
        isBrewInstalled = env.isInstalled
        brewExecutable = env.brewPath
        brewVersion = env.version
        installedFormulae = env.installedFormulae
        installedCasks = env.installedCasks
        outdatedFormulae = env.outdatedFormulae
        outdatedCasks = env.outdatedCasks
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
        let result = await managePackageUseCase.executeAction("install", package: pkg, brewPath: brew)
        if result.success {
            states[pkg.id] = .installed
            if pkg.kind == .formula { installedFormulae.insert(pkg.name) } else { installedCasks.insert(pkg.name) }
        } else if result.isPermissionError {
            states[pkg.id] = .permissionNeeded(result.output)
        } else {
            states[pkg.id] = .failed(result.output)
        }
    }

    func uninstall(_ pkg: BrewPackage) async {
        guard let brew = brewExecutable else { return }
        states[pkg.id] = .working(L("삭제 중..."))
        let result = await managePackageUseCase.executeAction("uninstall", package: pkg, brewPath: brew)
        if result.success {
            states[pkg.id] = .notInstalled
            if pkg.kind == .formula { installedFormulae.remove(pkg.name) } else { installedCasks.remove(pkg.name) }
            confirmCaskPermissionsIfNeeded(pkg)
        } else if result.isPermissionError {
            states[pkg.id] = .permissionNeeded(result.output)
        } else {
            states[pkg.id] = .failed(result.output)
        }
    }

    func update(_ pkg: BrewPackage) async {
        guard let brew = brewExecutable else { return }
        states[pkg.id] = .working(L("업데이트 중..."))
        let result = await managePackageUseCase.executeAction("upgrade", package: pkg, brewPath: brew)
        if result.success {
            states[pkg.id] = .installed
            if pkg.kind == .formula { outdatedFormulae.remove(pkg.name) } else { outdatedCasks.remove(pkg.name) }
            confirmCaskPermissionsIfNeeded(pkg)
        } else if result.isPermissionError {
            states[pkg.id] = .permissionNeeded(result.output)
        } else {
            states[pkg.id] = .failed(result.output)
        }
    }

    func updateAll() async {
        guard let brew = brewExecutable else { return }
        isUpdatingAll = true
        await managePackageUseCase.upgradeAll(brewPath: brew, hasOutdatedFormulae: !outdatedFormulae.isEmpty, hasOutdatedCasks: !outdatedCasks.isEmpty)
        isUpdatingAll = false
        await refreshStatus()
    }

    func installHomebrew() async {
        isInstallingBrew = true
        brewInstallLog = L("Homebrew 설치를 시작합니다. 관리자 암호를 입력해 주세요...\n")
        let result = await checkEnvironmentUseCase.installHomebrew()
        brewInstallLog += result.output
        isInstallingBrew = false
        await refreshStatus()
    }
}
