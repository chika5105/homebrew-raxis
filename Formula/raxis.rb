# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.1.1"
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.1.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "12c16025795e3a617f6816d3f90c7cdb5602062860b25b762dadbe7e51cfcfdb"
    sha256 cellar: :any_skip_relocation, tahoe:          "cd88bea7b05c41043fbdbf87ff44b26d12f571936bfedb2f1d4ddc816cc6f4bb"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "18e2642400764da85ac8a15ab45968890300690156f13e4c28af7cf2a223b692"
    sha256 cellar: :any_skip_relocation, sequoia:        "d03f75f727b5c9195b9fcac626ea090630185453d2082a99f1bb5d9affaa6ac0"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "d5c523447c97266b256e876ed6db932ab9cff72bd5f615289059183fa197a2db"
    sha256 cellar: :any_skip_relocation, sonoma:         "6eeabfe91b613adeb6325883d35037aeb950f153bac345b52f6081fb66cfff8f"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "2a1aea7262248092ce88021474b47129addaa2c35969c609fa716d1cfa2b6f87"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "c83d902804500ef2d0b19b56495e3ef2695684e76e0a9a29391cfe12d512d88c"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.1/raxis-v0.1.1-darwin-arm64.tar.gz"
      sha256 "32383cdb6f51b2458443140411fc7962af1c59f391743b104026bc3a82c00c4a"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.1/raxis-v0.1.1-darwin-x86_64.tar.gz"
      sha256 "943e73bb81c9d5390386d53db8e8403ecc96b3e9a985d0b97ca1f69f1ab72e62"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.1/raxis-v0.1.1-linux-arm64.tar.gz"
      sha256 "76d9975e5702ff8b7c68caebe6d6bb2026223795543b398607e211211146ac0d"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.1/raxis-v0.1.1-linux-x86_64.tar.gz"
      sha256 "2252417bb83ce05934ca1ce6a9e03c5fe01af3f350bde4910bf507ad59115712"
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
