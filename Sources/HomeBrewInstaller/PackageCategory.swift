import Foundation
import SwiftUI

enum PackageCategory: String, CaseIterable, Identifiable, Hashable {
    case developer = "개발자 도구"
    case productivity = "생산성"
    case utility = "유틸리티"
    case design = "디자인 & 크리에이티브"
    case communication = "소통 & 메신저"
    case media = "미디어 & 엔터테인먼트"
    case browser = "브라우저 & 웹"
    case security = "보안 & 네트워크"
    case ai = "AI & 데이터"
    case other = "기타"

    var id: String { rawValue }

    var displayName: String { L(rawValue) }

    var systemImage: String {
        switch self {
        case .developer: return "hammer"
        case .productivity: return "briefcase"
        case .utility: return "wrench.and.screwdriver"
        case .design: return "paintbrush"
        case .communication: return "message"
        case .media: return "play.tv"
        case .browser: return "globe"
        case .security: return "shield.checkerboard"
        case .ai: return "brain"
        case .other: return "ellipsis.circle"
        }
    }

    var accentColor: SwiftUI.Color {
        switch self {
        case .developer: return .blue
        case .productivity: return .orange
        case .utility: return .gray
        case .design: return .purple
        case .communication: return .green
        case .media: return .red
        case .browser: return .cyan
        case .security: return .indigo
        case .ai: return .mint
        case .other: return .secondary
        }
    }

    /// Smart categorization based on package token, name, and description.
    static func categorize(_ pkg: BrewPackage) -> PackageCategory {
        let name = pkg.name.lowercased()
        let desc = pkg.desc.lowercased()
        let displayName = pkg.displayName.lowercased()

        if isDeveloperTool(name: name, desc: desc, displayName: displayName) { return .developer }
        if isAI(name: name, desc: desc, displayName: displayName) { return .ai }
        if isSecurity(name: name, desc: desc, displayName: displayName) { return .security }
        if isBrowser(name: name, desc: desc, displayName: displayName) { return .browser }
        if isCommunication(name: name, desc: desc, displayName: displayName) { return .communication }
        if isMedia(name: name, desc: desc, displayName: displayName) { return .media }
        if isDesign(name: name, desc: desc, displayName: displayName) { return .design }
        if isProductivity(name: name, desc: desc, displayName: displayName) { return .productivity }
        if isUtility(name: name, desc: desc, displayName: displayName) { return .utility }

        return .other
    }

    private static func isDeveloperTool(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "visual-studio-code", "vscode", "xcode", "git", "docker", "postman", "iterm2",
            "sublime-text", "intellij", "pycharm", "webstorm", "clion", "neovim", "vim", "emacs",
            "cursor", "insomnia", "dbeaver", "sequel-ace", "tableplus", "charles", "wireshark",
            "android-studio", "kotlin", "swift", "python", "node", "rust", "go", "java", "ruby",
            "cmake", "gradle", "maven", "tmux", "zsh", "bash", "fish", "compiler", "debugger",
            "sdk", "api", "ide", "repository", "terminal", "command-line", "cli", "version control",
            "database", "sql", "gitclient", "code editor", "developer", "development"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }

    private static func isAI(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "ollama", "lm-studio", "chatgpt", "claude", "whisper", "jan", "copilot", "llm",
            "artificial intelligence", "machine learning", "neural", "deep learning", "gpt",
            "modelrunner", "diffusion", "ai client", "prompt"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }

    private static func isSecurity(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "vpn", "1password", "bitwarden", "keepass", "protonvpn", "mullvad", "wireguard",
            "tailscale", "firewall", "antivirus", "malware", "security", "privacy", "encrypt",
            "password", "keychain", "tor-browser", "authenticator", "2fa", "vault"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }

    private static func isBrowser(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "chrome", "firefox", "safari", "arc", "brave-browser", "opera", "edge", "chromium",
            "vivaldi", "browser", "web browser", "orion"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }

    private static func isCommunication(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "slack", "discord", "telegram", "whatsapp", "signal", "zoom", "microsoft-teams",
            "skype", "spark", "thunderbird", "mail", "chat", "messenger", "email", "meeting",
            "social", "communication", "matrix", "element", "irc"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }

    private static func isMedia(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "vlc", "iina", "spotify", "obs", "handbrake", "audacity", "quicktime", "player",
            "media player", "audio", "video", "screen recorder", "streaming", "music", "podcast",
            "radio", "converter", "ffmpeg", "transcoder", "mpv", "tidal"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }

    private static func isDesign(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "figma", "sketch", "blender", "gimp", "inkscape", "affinity", "photoshop",
            "illustrator", "canva", "pixelmator", "design", "graphic", "image editor", "photo",
            "vector", "3d", "canvas", "font", "color picker", "prototype", "cad", "modelling"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }

    private static func isProductivity(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "obsidian", "notion", "logseq", "alfred", "raycast", "craft", "bear", "evernote",
            "todoist", "things", "ticktick", "rectangle", "magnet", "linear", "office", "word",
            "excel", "powerpoint", "notes", "markdown", "document", "calendar", "task",
            "calculator", "pdf", "planner", "organizer", "spreadsheet"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }

    private static func isUtility(name: String, desc: String, displayName: String) -> Bool {
        let tokens = [
            "keka", "the-unarchiver", "cleanmymac", "appcleaner", "stats", "maccy", "bartender",
            "shottr", "snagit", "menu bar", "archiver", "zip", "clipboard", "window manager",
            "utility", "system", "disk", "benchmark", "cleaner", "file manager", "finder", "sync"
        ]
        return tokens.contains { name.contains($0) || desc.contains($0) || displayName.contains($0) }
    }
}
