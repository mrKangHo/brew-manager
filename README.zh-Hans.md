<p align="center">
  <img src="docs/icon.png" width="120" alt="Brew Manager 图标">
</p>

<h1 align="center">Brew Manager</h1>

<p align="center">
  用于安装和管理 <a href="https://brew.sh">Homebrew</a> 软件包的 macOS 原生 GUI 应用
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-Hans.md">中文</a>
</p>

<p align="center">
  <img src="docs/screenshot.png" width="800" alt="Brew Manager 截图">
</p>

## 功能

- 自动检测 Homebrew 是否已安装，未安装时可一键运行官方脚本安装
- 浏览 Homebrew 的完整目录(8,500+ 个 formula、7,700+ 个 cask)，按 formulae.brew.sh 的真实安装量数据排序
- Formulae / Apps(Cask) / 已安装 三个标签页 + 搜索功能(按 Enter 执行搜索)
- 一键安装、卸载、更新，并提供"全部更新"按钮批量更新可升级的软件包
- 点击任意软件包可查看详情页，包含描述、官网链接和安装状态
- 完整支持韩语、英语、日语、简体中文(自动跟随 macOS 系统语言)

## 安装

### Homebrew(推荐)

```bash
brew tap mrKangHo/brew-manager https://github.com/mrKangHo/brew-manager
brew install --cask brew-manager
```

### 手动安装

从 [Releases](../../releases) 页面下载最新版本，解压后将 `Brew Manager.app` 拖入 `/Applications`。

由于该构建未经 Apple 公证(notarization)，首次启动时会被 macOS Gatekeeper 拦截。可通过以下方式打开:

1. 右键点击 `Brew Manager.app` → **打开** → 在弹窗中再次点击 **打开**，或
2. 在终端运行: `xattr -cr "/Applications/Brew Manager.app"`

## 系统要求

- macOS 14 (Sonoma) 或更高版本
- [Homebrew](https://brew.sh) (若未安装，应用可代为安装)

## 从源码构建

```bash
git clone https://github.com/mrKangHo/brew-manager.git
cd brew-manager
./scripts/build-app.sh
open "dist/Brew Manager.app"
```

需要 Xcode Command Line Tools (Swift 5.9+)。

## 声明

本应用为非官方第三方客户端，与 Homebrew 项目无关。

## 许可证

MIT
