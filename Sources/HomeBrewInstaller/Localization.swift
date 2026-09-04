import Foundation

/// SwiftPM's generated `Bundle.module` only looks for the resource bundle
/// next to `Bundle.main.bundleURL` (a packaged app's top level, e.g.
/// `Brew Manager.app/`). Since this app is assembled by hand into a
/// standard `.app` bundle with resources under `Contents/Resources`
/// (required for a valid code signature), `Bundle.module` can't find it
/// there and fatalErrors on launch. Resolve it ourselves, checking the
/// standard app-bundle location first and falling back to the SwiftPM
/// dev-run layout (`swift run`).
private let moduleBundle: Bundle = {
    let bundleName = "HomeBrewInstaller_HomeBrewInstaller.bundle"
    let candidates = [
        Bundle.main.resourceURL,
        Bundle.main.bundleURL,
    ]
    for base in candidates {
        if let url = base?.appendingPathComponent(bundleName), let bundle = Bundle(url: url) {
            return bundle
        }
    }
    return Bundle.main
}()

private let resolvedBundle: Bundle = {
    let preferred = Bundle.preferredLocalizations(from: moduleBundle.localizations, forPreferences: Locale.preferredLanguages)
    guard let lang = preferred.first,
          let path = moduleBundle.path(forResource: lang, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        return moduleBundle
    }
    return bundle
}()

func L(_ key: String) -> String {
    resolvedBundle.localizedString(forKey: key, value: key, table: nil)
}

func LF(_ key: String, _ args: CVarArg...) -> String {
    String(format: L(key), arguments: args)
}
