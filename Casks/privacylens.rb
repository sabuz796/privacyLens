cask "privacylens" do
  version "1.0.1"
  sha256 "d90a8f1b0d3a1b713af8cc5430d080be54e4e73e13aff7779219d3079c85b634"

  url "https://github.com/sabuz796/privacyLens/releases/download/v#{version}/PrivacyLens.dmg"
  name "PrivacyLens"
  desc "See every installed app's privacy permissions in one searchable list"
  homepage "https://github.com/sabuz796/privacyLens"

  depends_on macos: :sonoma

  app "PrivacyLens.app"

  zap trash: [
    "~/Library/Preferences/com.privacylens.app.plist",
    "~/Library/Saved Application State/com.privacylens.app.savedState",
  ]
end
