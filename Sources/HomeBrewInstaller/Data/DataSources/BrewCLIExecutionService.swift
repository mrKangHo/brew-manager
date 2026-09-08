import Foundation
import AppKit

final class BrewCLIExecutionService: @unchecked Sendable {
    static let shared = BrewCLIExecutionService()
    static let candidatePaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]

    func findExecutable() -> String? {
        for path in Self.candidatePaths where FileManager.default.fileExists(atPath: path) {
            return path
        }
        return nil
    }

    func run(_ path: String, _ args: [String], extraEnv: [String: String] = [:]) async -> (output: String, success: Bool) {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args

            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:" + (env["PATH"] ?? "/usr/bin:/bin")
            for (key, value) in extraEnv { env[key] = value }
            process.environment = env

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { proc in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: (output, proc.terminationStatus == 0))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: ("실행 실패: \(error.localizedDescription)", false))
            }
        }
    }

    func runElevated(_ path: String, _ args: [String]) async -> (output: String, success: Bool) {
        guard let askpass = makeAskpassScript() else {
            return ("관리자 암호 입력창을 준비하지 못했습니다.", false)
        }
        defer { try? FileManager.default.removeItem(at: askpass) }
        return await run(path, args, extraEnv: ["SUDO_ASKPASS": askpass.path])
    }

    private func makeAskpassScript() -> URL? {
        let prompt = "Homebrew 작업에 관리자 암호가 필요합니다."
        let appleScript = "display dialog \"\(prompt)\" default answer \"\" with hidden answer with icon caution"
        let script = """
        #!/bin/sh
        osascript -e '\(appleScript)' -e 'text returned of result'
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("brewmanager-askpass-\(UUID().uuidString).sh")
        do {
            try script.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
            return url
        } catch {
            return nil
        }
    }

    func isPermissionError(_ output: String) -> Bool {
        let needles = [
            "Operation not permitted", "not permitted to send Apple events",
            "App Management", "Permission denied", "you don't have permission",
        ]
        return needles.contains { output.localizedCaseInsensitiveContains($0) }
    }

    func isSudoPasswordNeeded(_ output: String) -> Bool {
        let needles = [
            "a password is required", "sudo: a terminal is required", "sudo: no tty present",
        ]
        return needles.contains { output.localizedCaseInsensitiveContains($0) }
    }
}
