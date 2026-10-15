cask "privacylens" do
  version "1.0.0"
  sha256 "bdbc13444a075da7538fe352f28fc5dc2ddee0091ae9b5d8e852f9026414dec6"

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
