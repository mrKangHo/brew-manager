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
    @State private var searchDraft = ""
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
        guard !searchText.isEmpty else { return basePackages }
        return basePackages.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.desc.localizedCaseInsensitiveContains(searchText)
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
        .task {
            async let r = PopularityService.fetchRanks()
            async let c: Void = catalog.load()
            ranks = await r
            await c
            rebuildSortedLists()
            await brew.refreshStatus()
        }
        .onChange(of: selection) { visibleCount = Self.pageSize }
        .onChange(of: searchText) { visibleCount = Self.pageSize }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(L("검색"), text: $searchDraft)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        searchText = searchDraft
                    }
                if !searchDraft.isEmpty {
                    Button {
                        searchDraft = ""
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 4)

            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.displayName, systemImage: section.systemImage)
                    .badge(section == .installed ? brew.outdatedCount : 0)
                    .tag(section)
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Homebrew")
        .navigationSplitViewColumnWidth(200)
    }

    private var detail: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                statusBar
                Divider()

                if catalog.isLoading && basePackages.isEmpty {
                    Spacer()
                    ProgressView(L("Homebrew 전체 목록 불러오는 중...\n(최초 1회, 잠시 걸릴 수 있어요)"))
                        .multilineTextAlignment(.center)
                    Spacer()
                } else if let error = catalog.loadError, basePackages.isEmpty {
                    Spacer()
                    Text(error).foregroundStyle(.secondary)
                    Spacer()
                } else {
                    HStack {
                        Text(LF("총 %d개 중 %d개 표시", basePackages.count, pagedPackages.count))
                            .font(.caption)
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
                            .disabled(brew.isUpdatingAll)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    if filteredPackages.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            Text(searchText.isEmpty ? L("표시할 항목이 없습니다") : LF("\"%@\" 검색 결과가 없습니다", searchText))
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
                                onSelect: { navPath.append(pkg) }
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
        HStack {
            if brew.isBrewInstalled {
                Label(brew.brewVersion.isEmpty ? L("Homebrew 설치됨") : brew.brewVersion, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label(L("Homebrew 미설치"), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Button(L("Homebrew 설치")) {
                    showInstallSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
            Button {
                Task { await brew.refreshStatus() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help(L("상태 새로고침"))
        }
        .padding()
    }
}
