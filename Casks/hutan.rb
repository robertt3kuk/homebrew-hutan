cask "hutan" do
  version "0.1.0"
  sha256 "2b59b4c571249f487736e3303bc5dc66038af905390c00badcf9a8c9f480b0a8"

  url "https://github.com/robertt3kuk/hutan/releases/download/v#{version}/Hutan-#{version}-arm64.zip"
  name "Hutan"
  desc "Native agentic development environment"
  homepage "https://github.com/robertt3kuk/hutan"

  depends_on arch: :arm64
  depends_on macos: :ventura

  app "Hutan.app"
  binary "#{appdir}/Hutan.app/Contents/MacOS/hutan"

  uninstall launchctl: "dev.hutan.daemon",
            quit:      "dev.hutan.Hutan",
            script:    {
              executable:   "#{appdir}/Hutan.app/Contents/MacOS/hutan",
              args:         ["daemon", "stop"],
              must_succeed: false,
            }

  zap trash: [
    "~/Library/Application Support/Hutan",
    "~/Library/LaunchAgents/dev.hutan.daemon.plist",
    "~/Library/Logs/Hutan",
    "~/Library/Preferences/dev.hutan.Hutan.plist",
  ]

  caveats <<~EOS
    Hutan is ad-hoc signed, not notarized. macOS may block its first launch.
    If you trust this release, open it once, then use System Settings >
    Privacy & Security > Open Anyway and confirm Open. Quarantine is retained.
    Install either this cask or the hutan formula, not both (both provide hutan).
    Before uninstalling, turn off Start daemon at login in Hutan Settings.
  EOS
end
