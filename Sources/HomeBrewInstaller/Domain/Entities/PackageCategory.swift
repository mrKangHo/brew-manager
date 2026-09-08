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
        let target = "\(pkg.name) \(pkg.displayName) \(pkg.desc)".lowercased()

        if isDeveloperTool(target: target) { return .developer }
        if isAI(target: target) { return .ai }
        if isSecurity(target: target) { return .security }
        if isBrowser(target: target) { return .browser }
        if isCommunication(target: target) { return .communication }
        if isMedia(target: target) { return .media }
        if isDesign(target: target) { return .design }
        if isProductivity(target: target) { return .productivity }
        if isUtility(target: target) { return .utility }

        return .other
    }

    private static let developerTokens = [
        "visual-studio-code", "vscode", "xcode", "git", "docker", "postman", "iterm2",
        "sublime-text", "intellij", "pycharm", "webstorm", "clion", "neovim", "vim", "emacs",
        "cursor", "insomnia", "dbeaver", "sequel-ace", "tableplus", "charles", "wireshark",
        "android-studio", "kotlin", "swift", "python", "node", "rust", "go", "java", "ruby",
        "cmake", "gradle", "maven", "tmux", "zsh", "bash", "fish", "compiler", "debugger",
        "sdk", "api", "ide", "repository", "terminal", "command-line", "cli", "version control",
        "database", "sql", "gitclient", "code editor", "developer", "development"
    ]

    private static let aiTokens = [
        "ollama", "lm-studio", "chatgpt", "claude", "whisper", "jan", "copilot", "llm",
        "artificial intelligence", "machine learning", "neural", "deep learning", "gpt",
        "modelrunner", "diffusion", "ai client", "prompt"
    ]

    private static let securityTokens = [
        "vpn", "1password", "bitwarden", "keepass", "protonvpn", "mullvad", "wireguard",
        "tailscale", "firewall", "antivirus", "malware", "security", "privacy", "encrypt",
        "password", "keychain", "tor-browser", "authenticator", "2fa", "vault"
    ]

    private static let browserTokens = [
        "chrome", "firefox", "safari", "arc", "brave-browser", "opera", "edge", "chromium",
        "vivaldi", "browser", "web browser", "orion"
    ]

    private static let communicationTokens = [
        "slack", "discord", "telegram", "whatsapp", "signal", "zoom", "microsoft-teams",
        "skype", "spark", "thunderbird", "mail", "chat", "messenger", "email", "meeting",
        "social", "communication", "matrix", "element", "irc"
    ]

    private static let mediaTokens = [
        "vlc", "iina", "spotify", "obs", "handbrake", "audacity", "quicktime", "player",
        "media player", "audio", "video", "screen recorder", "streaming", "music", "podcast",
        "radio", "converter", "ffmpeg", "transcoder", "mpv", "tidal"
    ]

    private static let designTokens = [
        "figma", "sketch", "blender", "gimp", "inkscape", "affinity", "photoshop",
        "illustrator", "canva", "pixelmator", "design", "graphic", "image editor", "photo",
        "vector", "3d", "canvas", "font", "color picker", "prototype", "cad", "modelling"
    ]

    private static let productivityTokens = [
        "obsidian", "notion", "logseq", "alfred", "raycast", "craft", "bear", "evernote",
        "todoist", "things", "ticktick", "rectangle", "magnet", "linear", "office", "word",
        "excel", "powerpoint", "notes", "markdown", "document", "calendar", "task",
        "calculator", "pdf", "planner", "organizer", "spreadsheet"
    ]

    private static let utilityTokens = [
        "keka", "the-unarchiver", "cleanmymac", "appcleaner", "stats", "maccy", "bartender",
        "shottr", "snagit", "menu bar", "archiver", "zip", "clipboard", "window manager",
        "utility", "system", "disk", "benchmark", "cleaner", "file manager", "finder", "sync"
    ]

    private static func isDeveloperTool(target: String) -> Bool { developerTokens.contains { target.contains($0) } }
    private static func isAI(target: String) -> Bool { aiTokens.contains { target.contains($0) } }
    private static func isSecurity(target: String) -> Bool { securityTokens.contains { target.contains($0) } }
    private static func isBrowser(target: String) -> Bool { browserTokens.contains { target.contains($0) } }
    private static func isCommunication(target: String) -> Bool { communicationTokens.contains { target.contains($0) } }
    private static func isMedia(target: String) -> Bool { mediaTokens.contains { target.contains($0) } }
    private static func isDesign(target: String) -> Bool { designTokens.contains { target.contains($0) } }
    private static func isProductivity(target: String) -> Bool { productivityTokens.contains { target.contains($0) } }
    private static func isUtility(target: String) -> Bool { utilityTokens.contains { target.contains($0) } }
}

