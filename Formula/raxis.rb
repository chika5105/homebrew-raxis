# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.2.1"
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.2.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "6cc9b04f89e514b1341b0e0cc52422f81f9ffbf89e75147fbb1329c1ebc348d1"
    sha256 cellar: :any_skip_relocation, tahoe:          "08038b4b322ca92762b2258f4a9b2e13fb333c06f71ec83780d015b54d36bda2"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "985a38086c4eafad62073a65dce0458fc3a461fb9478d1c3c0e2fa963a8f428a"
    sha256 cellar: :any_skip_relocation, sequoia:        "493936f71ee84b566027a405484ea59fe5c7d00124a753b342c939d4a843b6e9"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "09cd335d61f579d0691abd2ca301419db5218b808516aa5481cd393bceeac652"
    sha256 cellar: :any_skip_relocation, sonoma:         "83696293ac1336d28594ef7ef0c1ccdc953f46e380de270f5f42f4555dfaa859"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "e441d85d2536b8b293e306c8c5cb9b66084f159e03228d9e12ce7de5ac362dd5"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "94179e0eff46e45e3d2e22ecb09af45b18afb945c18906031ad0d6ef1eade57b"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.1/raxis-v0.2.1-darwin-arm64.tar.gz"
      sha256 "ee9d7e839b3848d77cb4f148b2d0801935485ea2163ab4d991b6ff915dd991bf"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.1/raxis-v0.2.1-darwin-x86_64.tar.gz"
      sha256 "630683857b3661cbabd39fdcfb63c9f6f0c1ed93d62ec57a9f130070f4a329a9"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.1/raxis-v0.2.1-linux-arm64.tar.gz"
      sha256 "755e217db43fbafa8c31d62115c260d5acf789b10546576deada9f01d1d46b31"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.1/raxis-v0.2.1-linux-x86_64.tar.gz"
      sha256 "bafcad16b1992a7ad803ea0ffd0537ba6fdb22b2638c26415fff4b9c2f8969c3"
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
    pkgshare.install "share/raxis/install.sh" if File.exist?("share/raxis/install.sh")
    chmod 0755, pkgshare/"install.sh" if (pkgshare/"install.sh").exist?
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
    environment_variables PATH: std_service_path_env,
                          RAXIS_INSTALL_DIR: opt_pkgshare.to_s,
                          RAXIS_DATA_DIR: (var/"lib/raxis").to_s,
                          RAXIS_ENV: "default",
                          RAXIS_SUPERVISOR_AUTO_RESTART: "1",
                          RAXIS_SUPERVISOR_REQUIRE_INITIALIZED_DATA_DIR: "1",
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
        RAXIS_ENV=default
        RAXIS_SUPERVISOR_AUTO_RESTART=1
        RAXIS_SUPERVISOR_REQUIRE_INITIALIZED_DATA_DIR=1

      The service launches raxis-supervisor, which launches and
      supervises raxis-kernel.
      raxis-supervisor raises its own file-descriptor soft limit before
      starting raxis-kernel.

      Fast setup:
        #{opt_pkgshare}/install.sh

      Dashboard static bundle:
        #{opt_pkgshare}/dashboard
      To serve it, configure policy.toml with:
        [dashboard]
        static_dir = "#{opt_pkgshare}/dashboard"

      Start the kernel with:
        brew services start raxis

      Check daemon health with:
        RAXIS_DATA_DIR=#{var}/lib/raxis raxis-supervisor status
        RAXIS_DATA_DIR=#{var}/lib/raxis raxis doctor

      Logs:
        #{var}/log/raxis/kernel.log
        #{var}/log/raxis/kernel.err.log

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
