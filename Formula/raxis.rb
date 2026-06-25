# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

require "json"

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.3.4"

  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.3.4"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "0194fd68ea77d4efb865bf2a985135c9d1b9fa6f51b4c2d49c36926cde337305"
    sha256 cellar: :any_skip_relocation, tahoe:          "5b84d8ab01fdb9464c6cd58c87d4cf279d13b85cd37430b68f88f9c62e0dd6f7"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "92cce2b3e31a51b30261db6c93625cfc4cde4c4d960527a9c5b1fb4124c5e9ee"
    sha256 cellar: :any_skip_relocation, sequoia:        "7703a354a29fa30a100c0e855a73be93c08f26c1055e8d7bc711c1f3c4e6a5a8"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "25bb7471f50d5223028a6fd4f2d4237585d51a580215d3ea21161f76279119c3"
    sha256 cellar: :any_skip_relocation, sonoma:         "30a56f3867e05aa6f092a938ff910089220f61e5afb1caab43b104d25fae5ea7"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "c9f2eb6cf1f7bcbd2d87db54359e525caeb7ae528d65cf1ec75d93ea6b26894e"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "5568534f751fd71182d1fe08117a8d47568ecb6bcc62782a2e505fb7a1b74aa3"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.4/raxis-v0.3.4-darwin-arm64.tar.gz"
      sha256 "785b85210fa304c76cb2ff74c79eba81d0a9c1a42c5870cc5d246e706471f947"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.4/raxis-v0.3.4-darwin-x86_64.tar.gz"
      sha256 "8282f417188c3e8523b3cc2383f6357e9ce9583c2cc87c1a9353fcb3e85329ce"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.4/raxis-v0.3.4-linux-arm64.tar.gz"
      sha256 "797c0598bf07eee2706d4990a414117aec5ee4c173cb3eb537ad1f7c1b0d7d73"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.4/raxis-v0.3.4-linux-x86_64.tar.gz"
      sha256 "2a7235f2296864ac25392093a5a90bf9310b0cd776b453b18957b7328d64166a"
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
