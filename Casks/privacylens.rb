cask "privacylens" do
  version "1.0.0"
  sha256 "ce08befc4b9af91d6d2fbb13399288f2042e1687bdfe5951877e42c3d0cc590c"

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
