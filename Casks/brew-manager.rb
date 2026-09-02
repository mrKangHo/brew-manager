cask "brew-manager" do
  version "1.0.5"
  sha256 "e674be7bc83389e09b1803bf81b707c7fb9cf2fd4d2a753dc8f4fe088d50cd23"



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
