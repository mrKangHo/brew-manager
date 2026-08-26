import Foundation

private let resolvedBundle: Bundle = {
    let preferred = Bundle.preferredLocalizations(from: Bundle.module.localizations, forPreferences: Locale.preferredLanguages)
    guard let lang = preferred.first,
          let path = Bundle.module.path(forResource: lang, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        return Bundle.module
    }
    return bundle
}()

func L(_ key: String) -> String {
    resolvedBundle.localizedString(forKey: key, value: key, table: nil)
}

func LF(_ key: String, _ args: CVarArg...) -> String {
    String(format: L(key), arguments: args)
}
