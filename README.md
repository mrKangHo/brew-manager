🇰🇷 [한국어](README.md) | 🇺🇸 [English](README.en.md) | 🇯🇵 [日本語](README.ja.md) | 🇨🇳 [中文](README.zh.md)

<p align="center">
  <img src="docs/icon.png" width="128" alt="Brew Manager 아이콘">
</p>

<h1 align="center">Brew Manager</h1>

<p align="center">
  <a href="https://brew.sh">Homebrew</a> 패키지를 설치하고 관리하는 macOS 네이티브 GUI 앱
</p>

<p align="center">
  <img src="docs/screenshot.png" width="800" alt="Brew Manager 스크린샷">
</p>

## 주요 기능

- **App Store 스타일 그래픽 GUI**: 그리드 카드 & 리스트 뷰 전환, 추천 앱 쉘프, 카테고리 브라우징 제공
- **10개 지능형 카테고리 분류**: 개발자 도구, 생산성, 유틸리티, 디자인, 소통, 미디어, 브라우저, 보안, AI & 데이터, 기타
- Homebrew 설치 여부를 자동 감지하고, 미설치 시 공식 스크립트로 원클릭 설치
- Homebrew 전체 카탈로그(포뮬러 8,500개+, 캐스크 7,700개+)를 formulae.brew.sh의 실제 설치 통계 기준 인기순 탐색
- 키워드 실시간 즉시 검색 및 엔터 검색 지원
- 원클릭 설치 · 삭제 · 업데이트 및 전용 **업데이트 메뉴**를 통한 전체 업데이트 지원
- 항목 클릭 시 설명 · 홈페이지 링크 · 카테고리 뱃지 · 설치 상태를 보여주는 상세 화면 이동
- 한국어 · 영어 · 일본어 · 중국어 완전 다국어 지원 (macOS 시스템 언어 자동 반영)

## 설치 (Installation)

### Homebrew
```bash
brew tap mrKangHo/tap
brew install brew-manager
```

또는 공식 tap 직접 지정:
```bash
brew tap mrKangHo/brew-manager https://github.com/mrKangHo/brew-manager
brew install --cask brew-manager
```

### 수동 설치

[Releases](../../releases) 페이지에서 최신 빌드를 받아 압축을 풀고 `Brew Manager.app`을 `/Applications`로 이동합니다.

Apple 미공증 빌드이므로 첫 실행 시 다음과 같이 열 수 있습니다:
1. `Brew Manager.app` 우클릭 → **열기** → 대화상자에서 **열기**, 또는
2. 터미널 명령어: `xattr -cr "/Applications/Brew Manager.app"`

## 요구 사항

- macOS 14 (Sonoma) 이상
- [Homebrew](https://brew.sh) (미설치 시 앱 내에서 자동 설치 지원)
