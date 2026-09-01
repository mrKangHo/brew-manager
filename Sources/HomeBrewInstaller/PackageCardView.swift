import SwiftUI
import AppKit

struct PackageCardView: View {
    let pkg: BrewPackage
    let rank: Int?
    let state: InstallState
    let brewInstalled: Bool
    let isOutdated: Bool
    let onInstall: () -> Void
    let onUninstall: () -> Void
    let onUpdate: () -> Void
    let onSelect: () -> Void
    let onOpenPermissionSettings: () -> Void

    @State private var isHovered = false

    private var category: PackageCategory {
        PackageCategory.categorize(pkg)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                iconView

                VStack(alignment: .leading, spacing: 3) {
                    Text(pkg.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(pkg.kind == .formula ? "Formula" : "Cask")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 4, style: .continuous))

                        HStack(spacing: 3) {
                            Image(systemName: category.systemImage)
                                .font(.system(size: 8))
                            Text(category.displayName)
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundStyle(category.accentColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(category.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }

                Spacer(minLength: 0)

                if let rank {
                    Text("#\(rank)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                }
            }

            Text(pkg.desc.isEmpty ? L("설명 없음") : pkg.desc)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxHeight: .infinity, alignment: .topLeading)

            Divider()

            HStack {
                Spacer()
                actionView
            }
        }
        .padding(12)
        .frame(height: 155)
        .background(
            ZStack {
                Color(nsColor: .controlBackgroundColor).opacity(isHovered ? 0.95 : 0.75)
                LinearGradient(
                    colors: [category.accentColor.opacity(isHovered ? 0.08 : 0.03), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isHovered ? category.accentColor.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: isHovered ? 1.5 : 1)
        )
        .shadow(color: .black.opacity(isHovered ? 0.08 : 0.03), radius: isHovered ? 6 : 2, x: 0, y: isHovered ? 3 : 1)
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            isHovered = hovering
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
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
        .frame(width: 38, height: 38)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1.5)
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
            Image(systemName: pkg.kind == .formula ? "terminal" : "app.badge")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionView: some View {
        switch state {
        case .notInstalled:
            Button(L("설치"), action: onInstall)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!brewInstalled)
        case .installed:
            HStack(spacing: 6) {
                if isOutdated {
                    Button(L("업데이트"), action: onUpdate)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                } else {
                    Label(L("설치됨"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 11, weight: .medium))
                }
                Button(L("삭제"), role: .destructive, action: onUninstall)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        case .working(let msg):
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(msg).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        case .failed(let msg):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                Button(L("재시도"), action: onInstall)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .help(msg)
        case .permissionNeeded(let msg):
            HStack(spacing: 6) {
                Image(systemName: "lock.circle.fill").foregroundStyle(.orange)
                Button(L("권한 설정"), action: onOpenPermissionSettings)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .help(msg)
        }
    }
}
