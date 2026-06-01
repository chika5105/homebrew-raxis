# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.2.5"

  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.2.5"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "ec2a3486ec24a4be4088af4a214fb51e3a2bb8f739c1e59b6f9e627698db43fc"
    sha256 cellar: :any_skip_relocation, tahoe:          "2e89d1b892cf541f3846ac623071701fbdccef357a91c336fdd1469b63fd187f"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "014d8e4dea6d60c58213030128aa59b9e8d29bf2549571739bc3ec0cd835b8ab"
    sha256 cellar: :any_skip_relocation, sequoia:        "5aa17f39c7fd6d77611de762f920e01994b4c095fb10b3a0b9ab7392fbfdf117"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "493222bac2a253fd839c90e65e7cccda37c561b2bb9cd256664c6185eac9bff9"
    sha256 cellar: :any_skip_relocation, sonoma:         "f4fc9f1c31818d724c00f5d72117a3c8bdd65cc0a9cca20ba4f241ab65a0e336"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "a279bbc52a9e8f50b4c83838ffc05e95f44a6f438b5a99a8a0f2b6123c5ddf32"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "eabd692db0237b98ec127c7d5cdbc8559c0a68a234e983bc4f615c55f777dcdc"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.5/raxis-v0.2.5-darwin-arm64.tar.gz"
      sha256 "c726e1586994fdd4162a6f6cc1eb488958cb4db1a21f7abea465a75a0c4d6fdb"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.5/raxis-v0.2.5-darwin-x86_64.tar.gz"
      sha256 "fb8843f5ada8f9d0f020f39dbd38436d50360b858d5d3ed4b8ae0af405a2b2ea"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.5/raxis-v0.2.5-linux-arm64.tar.gz"
      sha256 "1d2b4ea91edfae7a70d3756232ea4bcae94d8085fde5166a52e1278952739cf3"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.5/raxis-v0.2.5-linux-x86_64.tar.gz"
      sha256 "83040822bac4fcf7a560dbd34898c3be5485ca717730034b10bb85b4bf450bf6"
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
      A verified local dashboard-only patch can be installed with:
        raxis dashboard install-bundle --from-file <bundle.tar.gz> --sha256 <hex>
      It is stored under #{var}/lib/raxis/dashboard/current and is
      preferred by new kernel starts over the packaged bundle.

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
