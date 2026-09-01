<p align="center">
  <img src="docs/icon.png" width="120" alt="Brew Manager icon">
</p>

<h1 align="center">Brew Manager</h1>

<p align="center">
  A native macOS GUI for installing and managing <a href="https://brew.sh">Homebrew</a> packages.
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-Hans.md">中文</a>
</p>

<p align="center">
  <img src="docs/screenshot.png" width="800" alt="Brew Manager screenshot">
</p>

## Features

- **App Store Style GUI**: Grid & List layout switcher with featured app shelf and category browsing
- **10 Intelligent Categories**: Developer Tools, Productivity, Utilities, Design, Communication, Media, Browsers, Security, AI & Data, and Other
- Detects whether Homebrew is installed, and installs it for you (one click, official script) if it isn't
- Browses the **entire** Homebrew catalog (8,500+ formulae, 7,700+ casks) ranked by real install-popularity data from formulae.brew.sh
- Real-time instant search with Enter submit support
- One-click install, uninstall, and update, with an "Update All" button for outdated packages
- Click any package to view a detail page with description, homepage link, category badge, and install status
- Fully localized: **Korean, English, Japanese, Simplified Chinese** (follows your macOS system language)

## Install

### Homebrew (recommended)

```bash
brew tap mrKangHo/brew-manager https://github.com/mrKangHo/brew-manager
brew install --cask brew-manager
```

### Manual

Download the latest build from the [Releases](../../releases) page, unzip it, and drag `Brew Manager.app` to `/Applications`.

Since this build isn't notarized by Apple, macOS Gatekeeper will block it on first launch. To open it:

1. Right-click `Brew Manager.app` → **Open** → **Open** again in the dialog, **or**
2. Run in Terminal: `xattr -cr "/Applications/Brew Manager.app"`

## Requirements

- macOS 14 (Sonoma) or later
- [Homebrew](https://brew.sh) (the app can install it for you)

## Build from source

```bash
git clone https://github.com/mrKangHo/brew-manager.git
cd brew-manager
./scripts/build-app.sh
open "dist/Brew Manager.app"
```

Requires Xcode Command Line Tools (Swift 5.9+).

## Disclaimer

This is an unofficial, third-party client. It is not affiliated with or endorsed by the Homebrew project.

## License

MIT
