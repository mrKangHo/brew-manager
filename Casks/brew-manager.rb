cask "brew-manager" do
  version "1.0.4"
  sha256 "eba77534909c9831e7ff9e1c9ed3ca537adb2d609f7e7d9a23d27a39f5f33ad9"

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
