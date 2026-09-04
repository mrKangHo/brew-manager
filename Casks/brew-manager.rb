cask "brew-manager" do
  version "1.0.8"
  sha256 "c5b18afa32602433292edc18517ec193d430f3e993c51f6c072699ad98a3d26b"





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
