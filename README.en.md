🇰🇷 [한국어](README.md) | 🇺🇸 [English](README.en.md) | 🇯🇵 [日本語](README.ja.md) | 🇨🇳 [中文](README.zh.md)

<p align="center">
  <img src="docs/icon.png" width="128" alt="Brew Manager icon">
</p>

<h1 align="center">Brew Manager</h1>

<p align="center">
  A native macOS GUI for installing and managing <a href="https://brew.sh">Homebrew</a> packages.
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
- One-click install, uninstall, and update, with a dedicated **Updates menu** and "Update All" button for outdated packages
- Click any package to view a detail page with description, homepage link, category badge, and install status
- Fully localized: **Korean, English, Japanese, Simplified Chinese** (follows your macOS system language)

## Installation

### Homebrew
```bash
brew tap mrKangHo/tap
brew install brew-manager
```

Or tap directly:
```bash
brew tap mrKangHo/brew-manager https://github.com/mrKangHo/brew-manager
brew install --cask brew-manager
```

### Manual

Download the latest build from the [Releases](../../releases) page, unzip it, and drag `Brew Manager.app` to `/Applications`.

## Requirements

- macOS 14 (Sonoma) or later
- [Homebrew](https://brew.sh)
