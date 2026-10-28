# Hutan Homebrew tap

Upstream-maintained, third-party packaging for [Hutan](https://github.com/robertt3kuk/hutan),
a native macOS agentic development environment. Requires **Apple Silicon and
macOS 13 (Ventura) or later**. Both packages install the exact archives of a
published GitHub release, pinned by SHA-256.

## Install

Choose **one**; both packages provide `hutan`, so they cannot be linked together:

```sh
brew install --cask robertt3kuk/hutan/hutan # Hutan.app + bundled CLI and daemon
# OR:
brew install robertt3kuk/hutan/hutan        # source-built CLI and daemon only
```

Upgrade with `brew upgrade --cask hutan` (app) or `brew upgrade hutan` (formula).

Homebrew 7 can ask you to trust this third-party package. Review it before
accepting; whole-tap trust is not required. If tapping separately, use
`brew trust --cask robertt3kuk/hutan/hutan` or
`brew trust --formula robertt3kuk/hutan/hutan` for the package you intend to use.

The cask links `hutan` from the installed app. The CLI resolves that symlink to
find the adjacent bundled `hutand`. The formula installs both binaries together
but **does not install the desktop, native notifications, or a login item**.
Start/stop its daemon explicitly with `hutan daemon start` / `hutan daemon stop`.

## Gatekeeper: read before opening

Hutan is **ad-hoc signed, not notarized**. An intact ad-hoc signature is
not an Apple Developer ID and does not satisfy Gatekeeper's normal downloaded-app
policy. Homebrew keeps quarantine on the download and installed app.

On first open macOS may say that the developer cannot be verified or that Apple
cannot check Hutan for malicious software (wording varies with macOS). If you
trust the exact release, first attempt to open Hutan, then go to **System
Settings → Privacy & Security → Open Anyway**, authenticate if asked, and
confirm **Open**. This creates an exception for that app. Managed Macs may not
allow this. A Homebrew package install does not itself approve first launch.
Allowing the app once has **not** been verified to approve its separate
`Contents/MacOS/hutan` CLI executable. The quarantined CLI was blocked locally;
the bundle-wide exception behavior needs a user-present test. Developer ID
signing and notarization would remove this ad-hoc distribution friction.

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
  Gatekeeper checks to pass. Hutan is pre-alpha and not notarized. An upstream
  tap is not Homebrew endorsement. Hutan is licensed MIT OR Apache-2.0 (the
  formula says `license any_of: ["MIT", "Apache-2.0"]`); its dependencies keep
  their own permissive licenses, checked by cargo-deny upstream.

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
unloads `dev.hutan.daemon`, quits the app, and sends TERM to registered
`dev.hutan.Hutan` processes. Homebrew 7 discovers those through application
labels in `launchctl list`; it cannot find an arbitrary plain process from its
code-signing identifier. A system `pkill -TERM` fallback therefore matches only
the current user's exact installed `Hutan.app/Contents/MacOS/hutand` path.
No Hutan executable is run during uninstall: an unapproved quarantined binary
can block even `--version` or `daemon stop`. A daemon already stopped is not an
uninstall failure. Stop the formula's daemon explicitly before removing it.

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
testing, replace that copy's `quit`, `signal` and `launchctl` bundle IDs with
`dev.hutan.homebrew-test`, so tests cannot quit or unregister a real user
installation. The `pkill` script is already scoped to the temporary appdir.
Do not publish those test substitutions. Commit the copy before tapping it:

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
an unreleased/private-to-local tap, a `file://` test URL, or the
ad-hoc signature. Do not suppress these to claim official eligibility. Run it
on the public definition too: release-URL checks cannot pass until publication.
Record failures separately from syntax/style and successful install tests.
Clean up only test-installed build dependencies; never autoremove pre-existing
formulae. No test needs to launch the desktop or touch the real Hutan data,
agent configs, login items, or Keychain.

## Local results for 0.3.1 (2026-10-28)

On Apple Silicon, Homebrew 7.0.10, from a committed temporary copy of this tap
(`file://` URLs to the generated archives, test-only bundle ID
`dev.hutan.homebrew-test`), tapped as `robertt3kuk/hutan-local`:

- `brew style` on the tap: **3 files inspected, no offenses**.
- `brew audit --strict` for the formula and the cask: **exit 0**. `brew audit
  --formula`: **exit 0**. `brew audit --cask --new`: the expected problems
  only, **3**: the repository is not notable enough, livecheck still finds
  0.3.0 (0.3.1 is not published), and the ad-hoc signature does not meet
  Gatekeeper's distributor requirements. The `file://` ZIP downloaded and
  extracted.
- Cask install into a scratch `--appdir`: **successful**; `codesign --verify
  --deep --strict` valid, quarantine present. The quarantined bundled `hutan
  --version` did not return within 60 seconds (as in 0.1.0, 0.2.0 and 0.3.0:
  first-open/CLI approval still needs a user at the Mac). The same executables
  from the ZIP, extracted without quarantine, are byte-identical to the
  installed ones and printed `hutan 0.3.1` and `hutand 0.3.1`. Uninstall with
  `HUTAN_HOME` on a scratch folder completed normally using system `pkill`,
  without running Hutan.
- Formula `brew install --build-from-source` from the local source archive:
  **successful**, 11 files, 34.5 MB, built in 5 minutes with Homebrew Rust
  1.99.1 (`cargo fetch`, then `cargo install` for `crates/cli` and
  `crates/daemon`, no GPUI). `hutan --version` printed **hutan 0.3.1**,
  `hutand --version` **hutand 0.3.1**, `brew test` passed, and `hutan daemon
  start|status|stop` worked on a scratch `HUTAN_HOME`.
- Both uninstalls, the untrust and the untap completed. The build dependencies
  installed for the test (`rust`, `llvm`, `libgit2`, `libssh2`, `llhttp`,
  `lz4`, `z3`, `zstd`, `pkgconf`, `readline`, `sqlite`, `openssl@4`,
  `ca-certificates`) were removed by name with autoremove disabled; the formula,
  cask and tap lists then matched those from before. Homebrew left the
  configuration folders `/opt/homebrew/etc/openssl@4` and
  `/opt/homebrew/etc/ca-certificates` behind. No app was installed in
  `/Applications`, and no real Hutan data, desktop or daemon was touched.

## Local results for 0.3.0 (2026-10-26)

On Apple Silicon, Homebrew 7.0.10, from a committed temporary copy of this tap
(`file://` URLs to the generated archives, test-only bundle ID
`dev.hutan.homebrew-test`), tapped as `robertt3kuk/hutan-local`:

- `brew style` on the tap: **2 files inspected, no offenses**.
- `brew audit --strict` for the formula and the cask: **exit 0**.
- `brew audit --formula`: **exit 0**. `brew audit --cask --new`: the expected
  problems only, **3**: the repository is not notable enough, livecheck still
  finds 0.2.0 (0.3.0 is not published), and the ad-hoc signature does not meet
  Gatekeeper's distributor requirements. The `file://` ZIP downloaded and
  extracted.
- Cask install into a scratch `--appdir`: **successful**; `codesign --verify
  --deep --strict` valid, quarantine present. The quarantined bundled `hutan
  --version` did not return within 60 seconds (as in 0.1.0 and 0.2.0:
  first-open/CLI approval still needs a user at the Mac). The same executables
  from the ZIP, extracted without quarantine, are byte-identical to the
  installed ones and printed `hutan 0.3.0` and `hutand 0.3.0`. Uninstall with
  `HUTAN_HOME` on a scratch folder completed normally using system `pkill`,
  without running Hutan.
- Formula `brew install --build-from-source` from the local source archive:
  **successful**, 11 files, 34.1 MB, built in 6 minutes with Homebrew Rust
  1.99.1 (`cargo fetch`, then `cargo install` for `crates/cli` and
  `crates/daemon`, no GPUI). `hutan --version` printed **hutan 0.3.0**,
  `hutand --version` **hutand 0.3.0**, `brew test` passed, and `hutan daemon
  start|status|stop` worked on a scratch `HUTAN_HOME`.
- Both uninstalls, the untrust and the untap completed. Homebrew removed the
  build dependencies installed for the test when the formula was uninstalled;
  the formula, cask and tap lists matched those from before. No app was
  installed in `/Applications`, and no real Hutan data, desktop or daemon was
  touched.

## Local results for 0.2.0 (2026-10-22)

On Apple Silicon, Homebrew 7.0.10, from a committed temporary copy of this tap:

- `brew style` on both definitions: **2 files inspected, no offenses**.
- `brew audit --strict` for the formula and the cask: **exit 0**.
- `brew audit --strict --online --formula` and `brew audit --cask --new`
  against the release URLs: only the expected problems before publication.
  The formula reports a source URL 404. The cask reports a ZIP 404, a binary
  URL 404, livecheck still at 0.1.0 and notability.
- With `file://` URLs to the generated archives: `brew audit --online --cask`
  downloaded and extracted the ZIP, reporting only livecheck, and
  `brew fetch --cask` verified the SHA-256.
- No Homebrew install was performed. The formula's build ran instead:
  `cargo fetch --locked`, then `cargo install --locked --offline` for
  `crates/cli` and `crates/daemon`, from the extracted source archive with
  `MACOSX_DEPLOYMENT_TARGET=13.0`. It compiled no GPUI and printed
  `hutan 0.2.0` and `hutand 0.2.0`. The formula's `test do` checks passed by
  hand, as did `hutan daemon start|status|stop`.

## Local results (2026-10-17)

On Apple Silicon macOS 26.6.2, Homebrew 7.0.9:

- `brew style` on both final definitions: **2 files inspected, no offenses**.
- `brew audit --formula robertt3kuk/hutan-review/hutan`: **exit 0**.
- `brew audit --cask --new robertt3kuk/hutan-review/hutan`: **4 eligibility
  problems**: no livecheck release yet, ZIP download 404, binary URL 404, and
  GitHub notability below official thresholds. These are not suppressed.
- Final local-file cask install into a scratch `--appdir`: **successful**;
  strict deep codesign verification passed and quarantine remained present.
  Final uninstall completed normally using system `pkill`, without running
  Hutan. Test-only bundle IDs prevented touching a real app/login item.
- Quarantined bundled `hutan --version` did not return within 120 seconds;
  `spctl --assess --type execute` rejected the ad-hoc app. No security bypass
  or automatic exception was used. First-open/CLI approval needs user testing.
- Real `brew install --formula --build-from-source --skip-link --no-ask`
  from a local source archive succeeded with Homebrew Rust **1.99.0_1**:
  **8 files, 21.2 MB, built in 9 minutes**. After linking, `hutan --version`
  printed **hutan 0.1.0**, `hutand --version` printed **hutand 0.1.0**;
  both `--help` commands and `brew test` passed.
  That source build used commit `2a6843a`; subsequent source changes concern
  only cask uninstall/packaging documentation, not the CLI/daemon or formula.
- The fallback's anchored, user-scoped TERM matcher was exercised on real
  test processes, including an app path containing spaces: the target exited
  with SIGTERM, while a same-name process in a different bundle stayed alive.
- Formula/cask uninstalls, all temporary untaps and trust removal completed.
  Only the six newly added build dependencies (`rust`, `llvm`, `libgit2`,
  `libssh2`, `pkgconf`, `z3`) were removed; before/after package lists matched.
  No app was installed in `/Applications`, no desktop or real daemon launched,
  and no real Hutan data, agent configuration or Keychain was touched.

## Open distribution decisions

1. ~~License~~: decided upstream, MIT OR Apache-2.0.
2. Obtain a stable Developer ID identity and notarize future releases if desired;
   until then the documented per-app Gatekeeper exception is a user decision.
