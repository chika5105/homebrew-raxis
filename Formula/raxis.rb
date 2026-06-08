# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.2.6"
  revision 1
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/dashboard-v0.2.6-r1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "8cc399666c3f972be6083054a42c7abca426728ad3a23053d3d7fb1c05ef17f1"
    sha256 cellar: :any_skip_relocation, tahoe:          "1e2ee6d5407fb1031547ed7edc1fc261bba184cd7d368e61714f6ea49ef24358"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "a9a3a69ef49c5814034944c7ff73658b144f3ed4fd23ede16ae1d380eee82672"
    sha256 cellar: :any_skip_relocation, sequoia:        "9002a78348580c20e5a2d32534593f293d533a2213dec41fe4c89bbca651b726"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "493dd5708f6b6737aa52c88c2f64cbbfc576548fb7c280e7f72e4698a32a4c24"
    sha256 cellar: :any_skip_relocation, sonoma:         "a3f0259882649b19f085b60689c0fa7fbf63ab1555bec932fb920b0e5a0574ff"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "4aff81ec379f7c494601c4ec94be36da25d72a712cb50d8ca8c1a7a78e043b83"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "fd7bf3c1ff7e9789bb6a6f4f1f73a2c8d8495cdcbb72010a7059f95d500b6db5"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.6/raxis-v0.2.6-darwin-arm64.tar.gz"
      sha256 "4f1c2cf53695b57a37375718857edf8835d186f30e01c963ab034b114a0fb49e"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.6/raxis-v0.2.6-darwin-x86_64.tar.gz"
      sha256 "94f8e774e89fc7455a3c2279e80fc5989d438d7d1ac7be0d762938bccbb83681"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.6/raxis-v0.2.6-linux-arm64.tar.gz"
      sha256 "c8cd0d5832f1b77287d25631e28ada47dbe414400c414f9d6e7546cfea4ea33f"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.6/raxis-v0.2.6-linux-x86_64.tar.gz"
      sha256 "378444102c39a4c62e68646605a1a8f0a4e5bb26b112fc206dd135671243fd68"
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

  def raxis_homebrew_auto_restart_disabled?
    disabled_values = %w[0 false no off]
    disabled_values.include?(ENV.fetch("RAXIS_BREW_AUTO_RESTART", "").downcase) ||
      disabled_values.include?(ENV.fetch("RAXIS_BREW_AUTO_REFRESH", "").downcase) ||
      (etc/"raxis/disable-brew-auto-restart").exist?
  end

  def raxis_homebrew_service_active?
    brew = HOMEBREW_PREFIX/"bin/brew"
    services = IO.popen([brew.to_s, "services", "list"], err: File::NULL, &:read)
    services.lines.any? do |line|
      columns = line.split
      columns[0] == "raxis" && %w[started error].include?(columns[1])
    end
  rescue
    false
  end

  def raxis_restart_homebrew_service_after_upgrade
    return unless raxis_homebrew_service_active?

    if raxis_homebrew_auto_restart_disabled?
      opoo "RAXIS Homebrew service is active but automatic restart is disabled."
      opoo "Run `brew services restart raxis` when you want the service to use this upgrade."
      return
    end

    ohai "Restarting active RAXIS Homebrew service so it uses this upgrade"
    system (HOMEBREW_PREFIX/"bin/brew").to_s, "services", "restart", "raxis"
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
    raxis_restart_homebrew_service_after_upgrade
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

      When `brew upgrade raxis` replaces this formula, an active RAXIS
      Homebrew service is restarted automatically so launchd/systemd stops
      using the old Cellar path. Stopped services are left stopped.
      Disable one automatic upgrade restart with:
        RAXIS_BREW_AUTO_RESTART=0 brew upgrade raxis
      Disable it persistently with:
        touch #{etc}/raxis/disable-brew-auto-restart

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
