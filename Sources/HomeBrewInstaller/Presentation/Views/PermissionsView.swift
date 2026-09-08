import SwiftUI

struct PermissionsView: View {
    @ObservedObject var brew: BrewManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("필요한 권한 안내")).font(.title2.bold())
            Text(L("Homebrew로 앱을 설치·업데이트·삭제하다 보면 macOS가 아래 권한을 요청하는 창을 띄울 수 있습니다. 뜨면 허용해 주세요."))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                permissionRow(
                    icon: "lock.shield",
                    title: L("관리자 암호"),
                    description: L("일부 앱(예: Docker Desktop)은 특권 헬퍼 파일을 정리할 때 관리자 암호가 필요합니다. 필요한 순간에 자동으로 암호 입력창이 뜹니다."),
                    action: nil
                )
                Divider()
                permissionRow(
                    icon: "app.badge.checkmark",
                    title: L("앱 관리"),
                    description: L("실행 중인 앱을 업데이트하거나 삭제하려면 다른 앱을 제어할 수 있는 권한이 필요합니다."),
                    action: (L("설정 열기"), brew.openAppManagementSettings),
                    confirmed: brew.caskPermissionsConfirmed
                )
                Divider()
                permissionRow(
                    icon: "gearshape.2",
                    title: L("자동화"),
                    description: L("일부 앱은 종료를 위해 다른 앱에 이벤트를 보내야 합니다. macOS가 대상 앱마다 개별적으로 허용을 물어봅니다."),
                    action: (L("설정 열기"), brew.openAutomationSettings),
                    confirmed: brew.caskPermissionsConfirmed
                )
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if !brew.caskPermissionsConfirmed {
                Button(L("시스템 설정에서 이미 둘 다 허용했어요")) {
                    brew.confirmPermissionsManually()
                }
                .buttonStyle(.link)
                .font(.caption)
            }

            HStack {
                Spacer()
                Button(L("확인")) {
                    brew.dismissPermissionsGuide()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480)
    }

    @ViewBuilder
    private func permissionRow(icon: String, title: String, description: String, action: (String, () -> Void)?, confirmed: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if confirmed {
                Label(L("설정됨"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else if let action {
                Button(action.0, action: action.1)
                    .controlSize(.small)
            }
        }
        .padding(12)
    }
}
