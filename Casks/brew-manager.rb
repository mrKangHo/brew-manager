cask "brew-manager" do
  version "1.0.0"
  sha256 "fb8e586c7f24300ed9b21f221b48b8a0a2d5a77ac40e82542630e2be6531876b"

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
