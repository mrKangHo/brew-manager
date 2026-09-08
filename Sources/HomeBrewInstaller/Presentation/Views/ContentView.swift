import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case all = "전체"
    case installed = "설치됨"
    case updates = "업데이트"

    var id: String { rawValue }

    var displayName: String { L(rawValue) }

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .installed: return "checkmark.circle"
        case .updates: return "arrow.clockwise.circle"
        }
    }
}



enum SidebarItem: Hashable, Identifiable {
    case section(SidebarSection)
    case category(PackageCategory)

    var id: String {
        switch self {
        case .section(let s): return "section-\(s.rawValue)"
        case .category(let c): return "category-\(c.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case .section(let s): return s.displayName
        case .category(let c): return c.displayName
        }
    }
}

enum ViewMode: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .grid: return "square.grid.2x2.fill"
        case .list: return "list.bullet"
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case rank = "인기순"
    case name = "이름순"

    var id: String { rawValue }
    var displayName: String { L(rawValue) }
}

struct ContentView: View {
    @StateObject private var brew = BrewManager()
    @StateObject private var catalog = CatalogStore()
    @State private var selection: SidebarItem = .section(.all)
    @State private var searchText = ""
    @State private var appliedSearchText = ""

    @State private var viewMode: ViewMode = .grid
    @State private var sortOption: SortOption = .rank
    @State private var ranks: [String: Int] = [:]
    @State private var showInstallSheet = false
    @State private var visibleCount = pageSize
    @State private var sortedAll: [BrewPackage] = []
    @State private var categoryCounts: [PackageCategory: Int] = [:]
    @State private var categoryPackages: [PackageCategory: [BrewPackage]] = [:]
    @State private var navPath: [BrewPackage] = []

    static let pageSize = 30

    var basePackages: [BrewPackage] {
        switch selection {
        case .section(let s):
            switch s {
            case .all: return sortedAll
            case .installed: return installedPackages
            case .updates: return outdatedPackages
            }
        case .category(let c):
            return categoryPackages[c] ?? []
        }
    }



    var sortedBasePackages: [BrewPackage] {
        switch sortOption {
        case .rank:
            return basePackages
        case .name:
            return basePackages.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        }
    }

    var installedPackages: [BrewPackage] {
        sortedAll.filter { pkg in
            pkg.kind == .formula ? brew.installedFormulae.contains(pkg.name) : brew.installedCasks.contains(pkg.name)
        }
    }

    var outdatedPackages: [BrewPackage] {
        installedPackages.filter { brew.isOutdated($0) }
    }

    private func badgeCount(for section: SidebarSection) -> Int {
        switch section {
        case .installed:
            return installedPackages.count
        case .updates:
            return brew.outdatedCount
        default:
            return 0
        }
    }

    var emptyStateText: String {
        if case .section(let s) = selection, s == .updates {
            return L("모든 패키지가 최신 버전입니다")
        }
        return L("표시할 항목이 없습니다")
    }



    var filteredPackages: [BrewPackage] {
        let query = appliedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sortedBasePackages }
        return sortedBasePackages.filter {
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
        sortedAll = Self.sortByRank(catalog.formulae + catalog.casks, ranks: ranks)
        rebuildCategoryData()
    }


    private func rebuildCategoryData() {
        var catMap: [PackageCategory: [BrewPackage]] = [:]
        var counts: [PackageCategory: Int] = [:]
        for pkg in sortedAll {
            let cat = PackageCategory.categorize(pkg)
            catMap[cat, default: []].append(pkg)
            counts[cat, default: 0] += 1
        }
        categoryPackages = catMap
        categoryCounts = counts
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
        .onChange(of: appliedSearchText) { visibleCount = Self.pageSize }
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
                    .onSubmit {
                        appliedSearchText = searchText
                    }
                if !searchText.isEmpty || !appliedSearchText.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            searchText = ""
                            appliedSearchText = ""
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

            List(selection: $selection) {
                Section {
                    ForEach(SidebarSection.allCases) { section in
                        Label(section.displayName, systemImage: section.systemImage)
                            .badge(badgeCount(for: section))
                            .tag(SidebarItem.section(section))
                    }
                }


                Section(header: Text(L("카테고리")).font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)) {
                    ForEach(PackageCategory.allCases) { category in
                        Label {
                            Text(category.displayName)
                        } icon: {
                            Image(systemName: category.systemImage)
                                .foregroundStyle(category.accentColor)
                        }
                        .badge(categoryCounts[category] ?? 0)
                        .tag(SidebarItem.category(category))
                    }
                }
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
                    HStack(spacing: 12) {
                        Text(LF("총 %d개 중 %d개 표시", basePackages.count, pagedPackages.count))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)

                        Spacer()

                        if case .section(let s) = selection, s == .updates && brew.outdatedCount > 0 {
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

                        HStack(spacing: 6) {
                            Text(L("정렬"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            Picker("", selection: $sortOption) {
                                ForEach(SortOption.allCases) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .frame(width: 110)
                        }

                        HStack(spacing: 6) {
                            Text(L("보기"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            Picker("", selection: $viewMode) {
                                ForEach(ViewMode.allCases) { mode in
                                    Image(systemName: mode.systemImage).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .frame(width: 66)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))

                    if filteredPackages.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: appliedSearchText.isEmpty ? (selection == .section(.updates) ? "checkmark.seal" : "tray") : "magnifyingglass")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(.tertiary)
                            Text(appliedSearchText.isEmpty ? emptyStateText : LF("\"%@\" 검색 결과가 없습니다", appliedSearchText))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else if viewMode == .grid {
                        ScrollView {
                            VStack(spacing: 16) {
                                if appliedSearchText.isEmpty && selection == .section(.all) {
                                    FeaturedShelfView(packages: sortedAll, ranks: ranks, brew: brew) { pkg in
                                        navPath.append(pkg)
                                    }
                                }



                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240, maximum: 300), spacing: 14)], spacing: 14) {
                                    ForEach(pagedPackages) { pkg in
                                        PackageCardView(
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
                                }
                            }
                            .padding(16)
                        }
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
