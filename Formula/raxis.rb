# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.1.2"
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.1.2"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "8cec112ada4574c7917c86c6e84cef4488eced97a55449130c268b1a77bf25b2"
    sha256 cellar: :any_skip_relocation, tahoe:          "d20f76e5c2018c920d0e8deabb308e55d61129cb6e9d1a93d4ae9bc483743b23"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "523153bf7d85178e689dc0fa97671ab796e313d6a443f413e1d936b3c26504ef"
    sha256 cellar: :any_skip_relocation, sequoia:        "48ee17af04cc2d48d58f085cfbe0766caf2b3e0f3826cb4fb1e5b4bfc14c21d4"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "a860f1806181fe78c5e55b0f74b65ff4a2dbb7dbbb941e4255a805686a9c14c3"
    sha256 cellar: :any_skip_relocation, sonoma:         "ca2c1246510330f93954e073ad564911d8c689c46b1efe37d1000e9c5814f204"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "3131b43e0d59cc98974d1841370cbec7bb9983200eac55a8dc58525c78033236"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "4e77a9fba442191588861b62c727fb1cf244a7d89d21a78a0e0c80ef0d10169b"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.2/raxis-v0.1.2-darwin-arm64.tar.gz"
      sha256 "e72b168550d5bf0abe15dbd5b0e569b45325139795d659f2122abdb8a3ad62c3"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.2/raxis-v0.1.2-darwin-x86_64.tar.gz"
      sha256 "c2507a181412a140566c868c282605f6218bafbf83592a0964b2f221b10ec60c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.2/raxis-v0.1.2-linux-arm64.tar.gz"
      sha256 "7dff16000253e36b496fe73e8495f9313a5422188cdc05c04ae4d2f4afb21631"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.2/raxis-v0.1.2-linux-x86_64.tar.gz"
      sha256 "66d939e351d2093970c48581c435babb686108dd8496c742416abd16e0a240d9"
    end
  end

  def install
    %w[
      raxis-kernel
      raxis-cli
      raxis
      raxis-gateway
      raxis-otel-pusher
      raxis-supervisor
      raxis-orchestrator
      raxis-executor
      raxis-reviewer
      raxis-tproxy
    ].each do |cmd|
      bin.install "bin/#{cmd}"
      chmod 0755, bin/cmd
    end

    pkgshare.install "images" if File.directory?("images")
    pkgshare.install "kernel" if File.directory?("kernel")
    pkgshare.install "share/raxis/dashboard" if File.directory?("share/raxis/dashboard")
    pkgshare.install "share/raxis/policy.toml.example" if File.exist?("share/raxis/policy.toml.example")

    install_policy_example
  end

  def install_policy_example
    policy_example = pkgshare/"policy.toml.example"
    return unless policy_example.exist?
    return if (etc/"raxis/policy.toml.example").exist?

    (etc/"raxis").mkpath
    (etc/"raxis").install policy_example
  end

  service do
    run [opt_bin/"raxis-supervisor", "start"]
    keep_alive true
    environment_variables RAXIS_INSTALL_DIR: opt_pkgshare.to_s,
                          RAXIS_DATA_DIR: (var/"lib/raxis").to_s,
                          RAXIS_SUPERVISOR_AUTO_RESTART: "1",
                          RAXIS_SUPERVISOR_KERNEL_BINARY: (opt_bin/"raxis-kernel").to_s
    log_path var/"log/raxis/kernel.log"
    error_log_path var/"log/raxis/kernel.err.log"
  end

  def post_install
    (var/"lib/raxis").mkpath
    (var/"log/raxis").mkpath
    install_policy_example

    system bin/"raxis", "doctor", "canonical-images",
                         "--install-dir", pkgshare.to_s
    system bin/"raxis", "doctor", "signing-key-fp"
  end

  def caveats
    <<~EOS
      RAXIS installed its immutable runtime bundle under:
        #{pkgshare}

      The Homebrew service runs with:
        RAXIS_INSTALL_DIR=#{opt_pkgshare}
        RAXIS_DATA_DIR=#{var}/lib/raxis
        RAXIS_SUPERVISOR_AUTO_RESTART=1

      The service launches raxis-supervisor, which launches and
      supervises raxis-kernel.

      Dashboard static bundle:
        #{opt_pkgshare}/dashboard
      To serve it, configure policy.toml with:
        [dashboard]
        static_dir = "#{opt_pkgshare}/dashboard"

      Start the kernel with:
        brew services start raxis

      Operator policy example:
        #{etc}/raxis/policy.toml.example
    EOS
  end

  test do
    %w[
      raxis-gateway
      raxis-otel-pusher
      raxis-supervisor
      raxis-orchestrator
      raxis-executor
      raxis-reviewer
      raxis-tproxy
    ].each do |cmd|
      assert_predicate bin/cmd, :executable?
    end

    assert_match "signing key fingerprint",
      shell_output("#{bin}/raxis doctor signing-key-fp")
  end
end
