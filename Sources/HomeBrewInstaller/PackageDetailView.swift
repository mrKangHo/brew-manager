import SwiftUI

struct PackageDetailView: View {
    let pkg: BrewPackage
    let rank: Int?
    @ObservedObject var brew: BrewManager

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                Divider()

                if !pkg.desc.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("설명")).font(.headline)
                        Text(pkg.desc).font(.body)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("정보")).font(.headline)
                    LabeledContent(L("이름"), value: pkg.name)
                    LabeledContent(L("종류"), value: pkg.kind.rawValue)
                    if let rank {
                        LabeledContent(L("인기 순위"), value: "#\(rank)")
                    }
                    if let homepage = pkg.homepage, let url = URL(string: homepage) {
                        LabeledContent(L("웹사이트")) {
                            Button {
                                openURL(url)
                            } label: {
                                Text(homepage)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .buttonStyle(.link)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(pkg.displayName)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            iconView
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 6) {
                Text(pkg.displayName).font(.largeTitle.bold())
                Text(pkg.kind.rawValue).font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            actionButton
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch brew.state(for: pkg) {
        case .notInstalled:
            Button(L("설치")) { Task { await brew.install(pkg) } }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!brew.isBrewInstalled)
        case .installed:
            HStack(spacing: 8) {
                if brew.isOutdated(pkg) {
                    Button(L("업데이트")) { Task { await brew.update(pkg) } }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else {
                    Label(L("설치됨"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                Button(L("삭제"), role: .destructive) { Task { await brew.uninstall(pkg) } }
                    .controlSize(.large)
            }
        case .working(let msg):
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(msg).foregroundStyle(.secondary)
            }
        case .failed:
            Button(L("재시도")) { Task { await brew.install(pkg) } }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        case .permissionNeeded:
            HStack(spacing: 8) {
                Button(L("권한 설정 열기")) { brew.openAppManagementSettings() }
                    .controlSize(.large)
                Button(L("재시도")) { Task { await brew.install(pkg) } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        Group {
            if let url = pkg.iconURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: pkg.kind == .formula ? "terminal" : "app.badge")
            .font(.system(size: 36))
            .foregroundStyle(.secondary)
    }
}
