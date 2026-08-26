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

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            if let rank {
                Text("#\(rank)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .leading)
            } else {
                Text("")
                    .frame(width: 36)
            }

            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(pkg.displayName).font(.headline)
                Text(pkg.desc).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            actionView
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            isHovering = hovering
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
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var fallbackIcon: some View {
        Image(systemName: pkg.kind == .formula ? "terminal" : "app.badge")
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var actionView: some View {
        switch state {
        case .notInstalled:
            Button(L("설치"), action: onInstall)
                .disabled(!brewInstalled)
        case .installed:
            HStack(spacing: 6) {
                if isOutdated {
                    Button(L("업데이트"), action: onUpdate)
                        .buttonStyle(.borderedProminent)
                } else {
                    Label(L("설치됨"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
                Button(L("삭제"), role: .destructive, action: onUninstall)
            }
        case .working(let msg):
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(msg).font(.caption).foregroundStyle(.secondary)
            }
        case .failed(let msg):
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                Button(L("재시도"), action: onInstall)
            }
            .help(msg)
        }
    }
}
