cask "brew-manager" do
  version "1.0.2"
  sha256 "8f92b5b348026aa6aaa49dfc34b6d32b49dfbf1549fa49904f145a6179172254"

  url "https://github.com/mrKangHo/brew-manager/releases/download/v#{version}/BrewManager-macOS-#{version}.zip"
  name "Brew Manager"
  desc "Native macOS GUI for installing and managing Homebrew packages"
  homepage "https://github.com/mrKangHo/brew-manager"

  depends_on macos: :sonoma

  app "Brew Manager.app"

  postflight do
    system_command "/usr/bin/xattr",
                    args: ["-cr", "#{appdir}/Brew Manager.app"],
                    sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.mrkanho.brewmanager.plist",
  ]
end
