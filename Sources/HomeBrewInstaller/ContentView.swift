import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case all = "전체"
    case formula = "Formulae"
    case cask = "Apps (Cask)"
    case installed = "설치됨"

    var id: String { rawValue }

    var displayName: String { L(rawValue) }

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .formula: return "terminal"
        case .cask: return "app.badge"
        case .installed: return "checkmark.circle"
        }
    }
}

struct ContentView: View {
    @StateObject private var brew = BrewManager()
    @StateObject private var catalog = CatalogStore()
    @State private var selection: SidebarSection = .all
    @State private var searchText = ""
    @State private var ranks: [String: Int] = [:]
    @State private var showInstallSheet = false
    @State private var visibleCount = pageSize
    @State private var sortedFormulae: [BrewPackage] = []
    @State private var sortedCasks: [BrewPackage] = []
    @State private var sortedAll: [BrewPackage] = []
    @State private var navPath: [BrewPackage] = []

    static let pageSize = 30

    var basePackages: [BrewPackage] {
        switch selection {
        case .all: return sortedAll
        case .formula: return sortedFormulae
        case .cask: return sortedCasks
        case .installed: return installedPackages
        }
    }

    var installedPackages: [BrewPackage] {
        sortedAll.filter { pkg in
            pkg.kind == .formula ? brew.installedFormulae.contains(pkg.name) : brew.installedCasks.contains(pkg.name)
        }
    }

    var filteredPackages: [BrewPackage] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return basePackages }
        return basePackages.filter {
            $0.displayName.localizedCaseInsensitiveContains(query) ||
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.desc.localizedCaseInsensitiveContains(query)
        }
    }

    private static func sortByRank(_ list: [BrewPackage], ranks: [String: Int]) -> [BrewPackage] {
        list.sorted { lhs, rhs in
            let l = ranks[lhs.name] ?? Int.max
            let r = ranks[rhs.name] ?? Int.max
            if l != r { return l < r }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    private func rebuildSortedLists() {
        sortedFormulae = Self.sortByRank(catalog.formulae, ranks: ranks)
        sortedCasks = Self.sortByRank(catalog.casks, ranks: ranks)
        sortedAll = Self.sortByRank(catalog.formulae + catalog.casks, ranks: ranks)
    }

    var pagedPackages: [BrewPackage] {
        Array(filteredPackages.prefix(visibleCount))
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .sheet(isPresented: $showInstallSheet) {
            InstallHomebrewView(brew: brew, isPresented: $showInstallSheet)
        }
        .sheet(isPresented: $brew.showPermissionsGuide) {
            PermissionsView(brew: brew, isPresented: $brew.showPermissionsGuide)
        }
        .task {
            async let r = PopularityService.fetchRanks()
            async let c: Void = catalog.load()
            ranks = await r
            await c
            rebuildSortedLists()
            await brew.refreshStatus()
            brew.maybeShowPermissionsGuide()
        }
        .onChange(of: selection) { visibleCount = Self.pageSize }
        .onChange(of: searchText) { visibleCount = Self.pageSize }
    }

    @State private var isRefreshing = false

    var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField(L("검색"), text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)

            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.displayName, systemImage: section.systemImage)
                    .badge(section == .installed ? brew.outdatedCount : 0)
                    .tag(section)
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Homebrew")
        .navigationSplitViewColumnWidth(210)
    }

    private var detail: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                statusBar
                Divider()

                if catalog.isLoading && basePackages.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text(L("Homebrew 전체 목록 불러오는 중...\n(최초 1회, 잠시 걸릴 수 있어요)"))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else if let error = catalog.loadError, basePackages.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    HStack {
                        Text(LF("총 %d개 중 %d개 표시", basePackages.count, pagedPackages.count))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if selection == .installed && brew.outdatedCount > 0 {
                            Button {
                                Task { await brew.updateAll() }
                            } label: {
                                if brew.isUpdatingAll {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text(LF("전체 업데이트 (%d)", brew.outdatedCount))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(brew.isUpdatingAll)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))

                    if filteredPackages.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(.tertiary)
                            Text(searchText.isEmpty ? L("표시할 항목이 없습니다") : LF("\"%@\" 검색 결과가 없습니다", searchText))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        List(pagedPackages) { pkg in
                            PackageRowView(
                                pkg: pkg,
                                rank: ranks[pkg.name],
                                state: brew.state(for: pkg),
                                brewInstalled: brew.isBrewInstalled,
                                isOutdated: brew.isOutdated(pkg),
                                onInstall: { Task { await brew.install(pkg) } },
                                onUninstall: { Task { await brew.uninstall(pkg) } },
                                onUpdate: { Task { await brew.update(pkg) } },
                                onSelect: { navPath.append(pkg) },
                                onOpenPermissionSettings: { brew.openAppManagementSettings() }
                            )
                            .onAppear {
                                guard pkg.id == pagedPackages.last?.id else { return }
                                guard visibleCount < filteredPackages.count else { return }
                                visibleCount += Self.pageSize
                            }
                        }
                        .listStyle(.inset)
                    }
                }
            }
            .navigationTitle(selection.displayName)
            .navigationDestination(for: BrewPackage.self) { pkg in
                PackageDetailView(pkg: pkg, rank: ranks[pkg.name], brew: brew)
            }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            if brew.isBrewInstalled {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text(brew.brewVersion.isEmpty ? L("Homebrew 설치됨") : brew.brewVersion)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1), in: Capsule())
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 7, height: 7)
                    Text(L("Homebrew 미설치"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1), in: Capsule())

                Button(L("Homebrew 설치")) {
                    showInstallSheet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            Spacer()
            
            Button {
                brew.presentPermissionsGuide()
            } label: {
                Image(systemName: "lock.shield")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(L("필요한 권한 안내"))

            Button {
                withAnimation(.linear(duration: 0.8)) {
                    isRefreshing = true
                }
                Task {
                    await brew.refreshStatus()
                    withAnimation {
                        isRefreshing = false
                    }
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(L("상태 새로고침"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
