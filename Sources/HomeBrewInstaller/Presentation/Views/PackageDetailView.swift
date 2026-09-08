import SwiftUI
import AppKit

struct PackageDetailView: View {
    let pkg: BrewPackage
    let rank: Int?
    @ObservedObject var brew: BrewManager

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                
                Divider()

                if !pkg.desc.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L("설명"))
                            .font(.system(size: 14, weight: .bold))
                        Text(pkg.desc)
                            .font(.system(size: 13))
                            .foregroundStyle(.primary.opacity(0.9))
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(L("정보"))
                        .font(.system(size: 14, weight: .bold))
                    
                    VStack(spacing: 8) {
                        LabeledContent(L("이름")) {
                            Text(pkg.name).font(.system(size: 13, design: .monospaced))
                        }
                        Divider()
                        LabeledContent(L("종류")) {
                            Text(pkg.kind.rawValue).font(.system(size: 13))
                        }
                        Divider()
                        LabeledContent(L("카테고리")) {
                            HStack(spacing: 4) {
                                Image(systemName: PackageCategory.categorize(pkg).systemImage)
                                    .font(.system(size: 11))
                                Text(PackageCategory.categorize(pkg).displayName)
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                        if let rank {
                            Divider()
                            LabeledContent(L("인기 순위")) {
                                Text("#\(rank)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                            }
                        }
                        if let homepage = pkg.homepage, let url = URL(string: homepage) {
                            Divider()
                            LabeledContent(L("웹사이트")) {
                                Button {
                                    openURL(url)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(homepage)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                .buttonStyle(.link)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(pkg.displayName)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 20) {
            iconView
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(pkg.displayName)
                        .font(.system(size: 24, weight: .bold))
                    
                    Text(pkg.kind == .formula ? "Formula" : "Cask")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.06), in: Capsule())
                }
                
                Text(pkg.name)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.green)
                }
                Button(L("삭제"), role: .destructive) { Task { await brew.uninstall(pkg) } }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
        case .working(let msg):
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text(msg).font(.system(size: 13)).foregroundStyle(.secondary)
            }
        case .failed:
            Button(L("재시도")) { Task { await brew.install(pkg) } }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        case .permissionNeeded:
            HStack(spacing: 8) {
                Button(L("권한 설정 열기")) { brew.openAppManagementSettings() }
                    .buttonStyle(.bordered)
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
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
            Image(systemName: pkg.kind == .formula ? "terminal" : "app.badge")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
