<p align="center">
  <img src="docs/icon.png" width="120" alt="Brew Manager アイコン">
</p>

<h1 align="center">Brew Manager</h1>

<p align="center">
  <a href="https://brew.sh">Homebrew</a> パッケージをインストール・管理するmacOSネイティブGUIアプリ
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-Hans.md">中文</a>
</p>

<p align="center">
  <img src="docs/screenshot.png" width="800" alt="Brew Manager スクリーンショット">
</p>

## 機能

- Homebrewのインストール状況を自動検出し、未インストールなら公式スクリプトでワンクリックインストール
- Homebrewの全カタログ(フォーミュラ8,500以上、キャスク7,700以上)をformulae.brew.shの実際のインストール統計に基づく人気順で閲覧
- Formulae / Apps(Cask) / インストール済み / **アップデート** タブ + 検索(Enterで検索実行)
- ワンクリックでインストール・削除・アップデート、専用のアップデートメニューでまとめて更新
- 項目をクリックすると説明・ウェブサイトリンク・インストール状態を表示する詳細画面に遷移
- 韓国語・英語・日本語・簡体字中国語に完全対応(macOSのシステム言語に自動追従)

## インストール

### Homebrew(推奨)

```bash
brew tap mrKangHo/brew-manager https://github.com/mrKangHo/brew-manager
brew install --cask brew-manager
```

### 手動インストール

[Releases](../../releases) ページから最新ビルドをダウンロードし、解凍して `Brew Manager.app` を `/Applications` に移動してください。

Appleの公証(notarization)を受けていないビルドのため、初回起動時にmacOS Gatekeeperにブロックされます。次のいずれかで開いてください:

1. `Brew Manager.app` を右クリック → **開く** → ダイアログでもう一度 **開く**、または
2. ターミナルで実行: `xattr -cr "/Applications/Brew Manager.app"`

## 動作環境

- macOS 14 (Sonoma) 以降
- [Homebrew](https://brew.sh) (未インストールでもアプリが導入可能)

## ソースからビルド

```bash
git clone https://github.com/mrKangHo/brew-manager.git
cd brew-manager
./scripts/build-app.sh
open "dist/Brew Manager.app"
```

Xcode Command Line Tools(Swift 5.9以上)が必要です。

## お断り

本アプリは非公式のサードパーティ製クライアントです。Homebrewプロジェクトとは関係ありません。

## ライセンス

MIT
