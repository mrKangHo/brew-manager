import SwiftUI

struct FeaturedShelfView: View {
    let packages: [BrewPackage]
    let ranks: [String: Int]
    let brew: BrewManager
    let onSelect: (BrewPackage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(L("추천 앱 및 툴"), systemImage: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(packages.prefix(6)) { pkg in
                        featuredCard(pkg)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.08), Color.indigo.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.purple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func featuredCard(_ pkg: BrewPackage) -> some View {
        HStack(spacing: 12) {
            Group {
                if let url = pkg.iconURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else {
                            Image(systemName: pkg.kind == .formula ? "terminal" : "app.badge")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: pkg.kind == .formula ? "terminal" : "app.badge")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 1.5)

            VStack(alignment: .leading, spacing: 3) {
                if let rank = ranks[pkg.name] {
                    Text("TOP #\(rank)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.blue)
                }

                Text(pkg.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)

                Text(pkg.desc)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(pkg) }
    }
}
