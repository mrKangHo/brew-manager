import SwiftUI

struct InstallHomebrewView: View {
    @ObservedObject var brew: BrewManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("Homebrew 설치")).font(.title2.bold())
            Text(L("공식 설치 스크립트를 실행합니다. 관리자 암호 입력 창이 표시됩니다."))
                .foregroundStyle(.secondary)

            ScrollView {
                Text(brew.brewInstallLog.isEmpty ? L("설치 버튼을 눌러 시작하세요.") : brew.brewInstallLog)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(height: 260)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)

            HStack {
                Spacer()
                Button(L("닫기")) { isPresented = false }
                Button(brew.isInstallingBrew ? L("설치 중...") : L("설치 시작")) {
                    Task { await brew.installHomebrew() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(brew.isInstallingBrew)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
