# Hutan Homebrew tap

Upstream-maintained, third-party packaging for [Hutan](https://github.com/robertt3kuk/hutan),
a native macOS agentic development environment. Requires **Apple Silicon and
macOS 13 (Ventura) or later**. The first release must be published before these
GitHub URLs can be installed; no release is fabricated by this repository.

## Install

Choose **one**; both packages provide `hutan`, so they cannot be linked together:

```sh
brew install --cask robertt3kuk/hutan/hutan # Hutan.app + bundled CLI and daemon
# OR:
brew install robertt3kuk/hutan/hutan        # source-built CLI and daemon only
```

Homebrew 7 can ask you to trust this third-party package. Review it before
accepting; whole-tap trust is not required. If tapping separately, use
`brew trust --cask robertt3kuk/hutan/hutan` or
`brew trust --formula robertt3kuk/hutan/hutan` for the package you intend to use.

The cask links `hutan` from the installed app. The CLI resolves that symlink to
find the adjacent bundled `hutand`. The formula installs both binaries together
but **does not install the desktop, native notifications, or a login item**.
Start/stop its daemon explicitly with `hutan daemon start` / `hutan daemon stop`.

## Gatekeeper: read before opening

Hutan 0.1.0 is **ad-hoc signed, not notarized**. An intact ad-hoc signature is
not an Apple Developer ID and does not satisfy Gatekeeper's normal downloaded-app
policy. Homebrew keeps quarantine on the download and installed app.

On first open macOS may say that the developer cannot be verified or that Apple
cannot check Hutan for malicious software (wording varies with macOS). If you
trust the exact release, first attempt to open Hutan, then go to **System
Settings → Privacy & Security → Open Anyway**, authenticate if asked, and
confirm **Open**. This creates an exception for that app. Managed Macs may not
allow this. A Homebrew package install does not itself approve first launch.

We deliberately do **not** clear quarantine, re-sign the app, recommend
`--no-quarantine`, disable Gatekeeper/SIP, or hide the warning in install hooks.
Homebrew 7's supported install options do not offer a quarantine bypass; a cask
cannot turn an ad-hoc build into a notarized one. A local-file install validates
packaging, not the downloaded-app user approval flow; the latter needs a user
at the Mac.

## Why these packages

- **Cask for the app:** use the exact versioned upstream GitHub release ZIP,
  `Hutan-<version>-arm64.zip`, pinned by SHA-256. Standard `app`, `binary`,
  `depends_on`, `uninstall` and `zap` stanzas, with no arbitrary install hook.
  Homebrew 7 style canonicalizes the requested `macos: ">= :ventura"` spelling to
  `macos: :ventura`; both mean macOS 13 or newer, so this tap uses the latter.
- **Formula for CLI + daemon only:** two `cargo install` calls using Homebrew's
  `std_cargo_args`, restricted to `crates/cli` and `crates/daemon`, avoid compiling
  the GPUI desktop and its large Zed Git dependency tree. Cargo still
  resolves/fetches pinned workspace dependencies;
  `cargo fetch --locked` runs in Homebrew's network-enabled fetch phase, and
  compilation runs offline. Building the whole workspace to install two
  command-line tools would impose unnecessary GUI dependencies and build cost.
  The formula uses the release's `git archive` source asset, not a mutable branch
  or GitHub's independently generated archive. Homebrew Rust is a build-only
  dependency; Hutan's minimum Rust version is 1.98.
- **Third-party, not official Homebrew:** the official repositories require a
  stable release and appropriate license; official casks additionally require
  Gatekeeper checks to pass. Hutan is pre-alpha, has no LICENSE yet, and is not
  notarized. An upstream tap is not Homebrew endorsement, and does not waive
  redistribution obligations. We intentionally omit a formula `license` field
  rather than claim a license upstream has not granted. Resolve licensing and
  dependency redistribution obligations before public redistribution.

Rules consulted (2026-10-17):
[creating a tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap),
[Cask Cookbook](https://docs.brew.sh/Cask-Cookbook),
[Homebrew 7 migration guide](https://brew.sh/7.0.0-migration-guide/),
[tap trust](https://docs.brew.sh/Tap-Trust),
[Formula Cookbook](https://docs.brew.sh/Formula-Cookbook),
[acceptable casks](https://docs.brew.sh/Acceptable-Casks),
[acceptable formulae](https://docs.brew.sh/Acceptable-Formulae),
[language-specific formulae](https://docs.brew.sh/Language-Specific-Formulae),
[Homebrew security model](https://docs.brew.sh/Homebrew-Security-and-Supply-Chain#casks-have-a-different-trust-model),
[Apple's first-open instructions](https://support.apple.com/en-us/102445).
The acceptance policies explicitly govern `homebrew/core` and `homebrew/cask`;
this tap still uses their package formats and checks, without claiming eligibility.

## Uninstall and data

Before uninstalling the app, turn off **Start daemon at login** in Hutan Settings
so `SMAppService` unregisters its bundled LaunchAgent. The cask additionally
unloads `dev.hutan.daemon`, quits the app and calls its bundled `hutan daemon
stop`; a daemon already stopped is not an uninstall failure. Stop the formula's
daemon explicitly before removing the formula.

```sh
brew uninstall --cask robertt3kuk/hutan/hutan
# Or remove app AND user data (destructive, only when intended):
brew uninstall --cask --zap robertt3kuk/hutan/hutan
# Formula:
hutan daemon stop
brew uninstall robertt3kuk/hutan/hutan
```

Normal cask uninstall preserves data. `--zap` removes
`~/Library/Application Support/Hutan`, `~/Library/Logs/Hutan`,
`~/Library/Preferences/dev.hutan.Hutan.plist` and
`~/Library/LaunchAgents/dev.hutan.daemon.plist` if present. The last path covers
legacy/manual registration; Hutan's SMAppService registration uses the plist
inside the app, not a copy in `~/Library/LaunchAgents`.

## Releases and local verification

Definitions are generated by the Hutan checkout's
`cargo run -p xtask -- release --tap /path/to/homebrew-hutan` from a clean,
committed source tree. It builds and signs once, creates the app ZIP with
`ditto -c -k --keepParent`, archives HEAD, prints both SHA-256s and updates both
Ruby definitions. Upload those exact two archives to release `v<version>`;
see [upstream packaging](https://github.com/robertt3kuk/hutan/blob/master/docs/packaging.md#homebrew)
for the manual publishing sequence. No workflow here publishes packages.

On an Apple Silicon Mac, use a **temporary copy** of this tap and point its URLs
at the generated local `file://` archives (keep the SHA-256s). For safe uninstall
testing, also replace the temporary cask's script executable with `/usr/bin/env`
and its arguments with `["HUTAN_HOME=/absolute/temp/home",
"#{appdir}/Hutan.app/Contents/MacOS/hutan", "daemon", "stop"]`.
**Homebrew scrubs `HUTAN_HOME` from its own environment**, so putting it only
before `brew uninstall` is not enough to isolate the script. Replace that copy's
`quit` and `launchctl` IDs with `dev.hutan.homebrew-test` too, so tests cannot quit
or unregister a real user installation. Do not publish these test substitutions.
Commit the temporary copy before tapping it:

```sh
brew tap robertt3kuk/hutan-local /absolute/path/to/temporary-tap
brew trust --cask robertt3kuk/hutan-local/hutan
brew trust --formula robertt3kuk/hutan-local/hutan
HOMEBREW_NO_AUTO_UPDATE=1 brew audit --cask --new robertt3kuk/hutan-local/hutan
HOMEBREW_NO_AUTO_UPDATE=1 brew audit --formula robertt3kuk/hutan-local/hutan
brew style robertt3kuk/hutan-local
# Supply an empty temporary app directory, never /Applications for this test:
HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask --appdir=/absolute/temp/apps robertt3kuk/hutan-local/hutan
HUTAN_HOME=/absolute/temp/home hutan --version
HUTAN_HOME=/absolute/temp/home brew uninstall --cask robertt3kuk/hutan-local/hutan
HOMEBREW_NO_AUTO_UPDATE=1 brew install --build-from-source robertt3kuk/hutan-local/hutan
HUTAN_HOME=/absolute/temp/home hutan --version
HUTAN_HOME=/absolute/temp/home hutand --version
brew test robertt3kuk/hutan-local/hutan
brew uninstall --formula robertt3kuk/hutan-local/hutan
brew untrust --cask robertt3kuk/hutan-local/hutan
brew untrust --formula robertt3kuk/hutan-local/hutan
brew untap robertt3kuk/hutan-local
```

`--new` implies online eligibility audits, so it may report expected failures for
an unreleased/private-to-local tap, a `file://` test URL, missing license, or the
ad-hoc signature. Do not suppress these to claim official eligibility. Run it
on the public definition too: release-URL checks cannot pass until publication.
Record failures separately from syntax/style and successful install tests.
Clean up only test-installed build dependencies; never autoremove pre-existing
formulae. No test needs to launch the desktop or touch the real Hutan data,
agent configs, login items, or Keychain.

## Open distribution decisions

1. Choose/add the upstream LICENSE and review dependency licenses; do not guess
   an SPDX value in this tap.
2. Obtain a stable Developer ID identity and notarize future releases if desired;
   until then the documented per-app Gatekeeper exception is a user decision.
3. Tag/publish the first release and create/push this tap after maintainer review.
