# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

require "json"

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.3.5"

  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.3.5"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "bb8de08c42a2ffafd8820dd56b741dc1fea25c2eb14410ee04993468a6e1a824"
    sha256 cellar: :any_skip_relocation, tahoe:          "c1cead9e92219e1f2521b646ed89b663e69aab226c877b4917bfd6918e7d6f89"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "5211410ee080e4e63e5a03d0ddd3e21381522dfe875edb9c413d07ed49e0b6cd"
    sha256 cellar: :any_skip_relocation, sequoia:        "104769db0f09376f42a699625175dcf6520422cdf2bc93dcc0ed6b7a574b163b"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "cf48e4f9f24bfb2747c4cb6d63d9c519decd95436c3e95e1169137e6c1d43589"
    sha256 cellar: :any_skip_relocation, sonoma:         "34ed4412d14efe55a9d2695585ffb68642f158063d41ce582e0e30fcc8258753"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "b5adf8c2fa2e5a2624b9a7aaf96e4449a84b6178d7013ab7155b996231ee02ac"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "4cfc3983766b024e7ed38cc1819758698b5eee9dcd97aa90b3200b2b199874d7"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.5/raxis-v0.3.5-darwin-arm64.tar.gz"
      sha256 "2e928ccdfb4bb36ebbd960a2829a73441a24f787ea68e88bf51b10648e06e276"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.5/raxis-v0.3.5-darwin-x86_64.tar.gz"
      sha256 "d63c14d630b9b5abc9c2defaa0231c5107dc762c21f07fed8cf80550e1068e76"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.5/raxis-v0.3.5-linux-arm64.tar.gz"
      sha256 "1a9d976ec56eb91fa2d6bbbe1cfe4243ebbceca0a0d5a2d37dc68f84f5dbc816"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.5/raxis-v0.3.5-linux-x86_64.tar.gz"
      sha256 "c39463a8aa55747c9ab0ab0dfce55995655f2224801d6552816bd5b729dc0e43"
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

  def raxis_homebrew_service_active_from_list?
    brew = HOMEBREW_PREFIX/"bin/brew"
    services = IO.popen([brew.to_s, "services", "list"], err: File::NULL, &:read)
    services.lines.any? do |line|
      columns = line.split
      columns[0] == "raxis" && %w[started error].include?(columns[1])
    end
  rescue
    false
  end

  def raxis_homebrew_service_managed?
    brew = HOMEBREW_PREFIX/"bin/brew"
    services = IO.popen([brew.to_s, "services", "info", "raxis", "--json"], err: File::NULL, &:read)
    JSON.parse(services).any? do |entry|
      entry["name"] == "raxis" && (
        entry["registered"] ||
        entry["loaded"] ||
        %w[started error].include?(entry["status"].to_s)
      )
    end
  rescue
    raxis_homebrew_service_active_from_list?
  end

  def raxis_launchctl_restart_loaded_service
    return false unless OS.mac?

    domain = "gui/#{Process.uid}"
    label = "homebrew.mxcl.raxis"
    target = "#{domain}/#{label}"
    return false unless system "/bin/launchctl", "print", target,
                               out: File::NULL, err: File::NULL

    ohai "Restarting loaded RAXIS launchd service so it uses this upgrade"
    system "/bin/launchctl", "kickstart", "-k", target
  end

  def raxis_systemd_restart_loaded_service
    return false unless OS.linux?

    %w[
      homebrew.raxis.service
      homebrew.mxcl.raxis.service
    ].any? do |unit|
      next false unless system "systemctl", "--user", "is-active", "--quiet", unit,
                               out: File::NULL, err: File::NULL

      ohai "Restarting loaded RAXIS systemd service so it uses this upgrade"
      system "systemctl", "--user", "restart", unit
    end
  end

  def raxis_restart_homebrew_service_after_upgrade
    return unless raxis_homebrew_service_managed?

    if raxis_homebrew_auto_restart_disabled?
      opoo "RAXIS Homebrew service is managed but automatic restart is disabled."
      opoo "Run `brew services restart raxis` when you want the service to use this upgrade."
      return
    end

    return if raxis_launchctl_restart_loaded_service
    return if raxis_systemd_restart_loaded_service

    opoo "RAXIS Homebrew service is managed, but no loaded launchd/systemd unit was found."
    opoo "Run `brew services restart raxis` when you want the service to use this upgrade."
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
        RAXIS_INSTALL_DIR=#{pkgshare}
        RAXIS_DATA_DIR=#{var}/lib/raxis
        RAXIS_ENV=default
        RAXIS_SUPERVISOR_AUTO_RESTART=1
        RAXIS_SUPERVISOR_REQUIRE_INITIALIZED_DATA_DIR=1

      The service launches raxis-supervisor, which launches and
      supervises raxis-kernel.
      raxis-supervisor raises its own file-descriptor soft limit before
      starting raxis-kernel.

      Fast setup:
        #{pkgshare}/install.sh

      Dashboard static bundle:
        #{pkgshare}/dashboard
      To serve it, configure policy.toml with:
        [dashboard]
        static_dir = "#{pkgshare}/dashboard"
      A verified local dashboard-only patch can be installed with:
        raxis dashboard install-bundle --from-file <bundle.tar.gz> --sha256 <hex>
      It is stored under #{var}/lib/raxis/dashboard/current and is
      preferred by new kernel starts over the packaged bundle.

      Start the kernel with:
        brew services start raxis

      When `brew upgrade raxis` replaces this formula, a Homebrew-managed
      RAXIS service is restarted automatically so launchd/systemd stops
      using the old Cellar path. Fresh installs and never-enabled services
      are left stopped.
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
