import SwiftUI
import AppKit

struct PackageRowView: View {
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

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            if let rank {
                Text("#\(rank)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.06), in: Capsule())
                    .frame(width: 44, alignment: .center)
            } else {
                Spacer().frame(width: 44)
            }

            iconView

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(pkg.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    
                    Text(pkg.kind == .formula ? "Formula" : "Cask")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                
                Text(pkg.desc)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            actionView
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = hovering
            }
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
        .frame(width: 32, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
            Image(systemName: pkg.kind == .formula ? "terminal" : "app.badge")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionView: some View {
        switch state {
        case .notInstalled:
            Button(L("설치"), action: onInstall)
                .buttonStyle(.bordered)
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
                Text(msg).font(.system(size: 11)).foregroundStyle(.secondary)
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
                Button(L("권한 설정 열기"), action: onOpenPermissionSettings)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button(L("재시도"), action: onInstall)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .help(msg)
        }
    }
}
