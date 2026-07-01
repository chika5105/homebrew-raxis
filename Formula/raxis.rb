# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

require "json"

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.3.7"

  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.3.7"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "5e00490fbe480beb3182605f0c6fc757f75e87f8578b77db3dd371d0a7735511"
    sha256 cellar: :any_skip_relocation, tahoe:          "1388058c9c59e055a7e3fe3c48057c2ce97014b51452adfc02bd4bc06544e55e"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "418bd46bbbc10e1b2b54ff0a9e1bbed9a2eadb1f58b6b90ccf04f032dfd544cc"
    sha256 cellar: :any_skip_relocation, sequoia:        "f8698545f1e4d304d0d24c70327d7c958767333867fd4e1a674a80beae9b3bf6"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "a711463eedf2afc2f26d726ad20ce0d954cc79a9456fe3d4d6a5481826c2b14d"
    sha256 cellar: :any_skip_relocation, sonoma:         "7eed508ae0839c8df26fb2432a28e57a8b9051b934e1921ebe0a973311238eef"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "0c52d3815715a53cb7d18eb33af5250b5bcc15b3e6558f5d4879e2862650e3b2"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "15d204e3cb34480a87e615d5ddaace6afa4f38ef7d4b6d67ddb2a8574c4a8d0a"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.7/raxis-v0.3.7-darwin-arm64.tar.gz"
      sha256 "c68441858045063b25ca515212b27a2d107bdeb01ec37663f8f79578d96e83cd"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.7/raxis-v0.3.7-darwin-x86_64.tar.gz"
      sha256 "f6f11943f153a69c7de61d14717643187bb53f007c5c9c27a702af5876a80869"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.7/raxis-v0.3.7-linux-arm64.tar.gz"
      sha256 "f89d28e23390a492cfc66a12189ee329a338a7ce4056a576b6c89de9fae5340c"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.7/raxis-v0.3.7-linux-x86_64.tar.gz"
      sha256 "24afb24c1ee5ef0609616c736a9b6153434869dbca47097abc80810675e1fe26"
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
