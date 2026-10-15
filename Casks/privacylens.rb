cask "privacylens" do
  version "1.0.2"
  sha256 "44514874da08c7daed419b14f0a63824b85ec19f685b8fa9b7458f88cac4f0a5"

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
