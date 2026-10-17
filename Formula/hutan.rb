class Hutan < Formula
  desc "Command-line client and daemon for the Hutan development environment"
  homepage "https://github.com/robertt3kuk/hutan"
  url "https://github.com/robertt3kuk/hutan/releases/download/v0.1.0/Hutan-0.1.0-source.tar.gz"
  sha256 "3fe786af1503baea99d4fe82e7ada43919037bd08c06f820fd6f5314ef8e67fa"
  # Upstream has not chosen a license; do not invent an SPDX identifier.

  depends_on "rust" => :build
  depends_on arch: :arm64
  depends_on macos: :ventura

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "13.0"
    system "cargo", "install", *std_cargo_args(path: "crates/cli")
    system "cargo", "install", *std_cargo_args(path: "crates/daemon")
  end

  def caveats
    <<~EOS
      This formula installs only the CLI and daemon, not Hutan.app or native notifications.
      Start explicitly with: hutan daemon start
      Stop before uninstalling with: hutan daemon stop
      Install either this formula or the hutan cask, not both (both provide hutan).
    EOS
  end

  test do
    ENV["HUTAN_HOME"] = testpath/"home"
    assert_match version.to_s, shell_output("#{bin}/hutan --version")
    assert_match version.to_s, shell_output("#{bin}/hutand --version")
    assert_match "daemon", shell_output("#{bin}/hutan --help")
    assert_match "Hutan", shell_output("#{bin}/hutand --help")
  end
end
