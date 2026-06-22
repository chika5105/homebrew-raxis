# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

require "json"

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.3.3"
  revision 1
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/dashboard-v0.3.3-r1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "f453c6db7e52e079886a5f078aba69f1cde4a05d4f7d8255daaad12fd0fe2bac"
    sha256 cellar: :any_skip_relocation, tahoe:          "bbee5edb66bfccfbdbc05cba601437993e2f51ef6673476cc9eb9fe82fc85758"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "ccff6c27ce91be9297bedd0716dfa8964781b4a9d335ae1124bc98a6a3c1416f"
    sha256 cellar: :any_skip_relocation, sequoia:        "6d25abfdfd1f21ca60579d7e0ca31df5dd7838430cebfc8017f478b527736a48"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "bd4bbf26e349a622d46a5c02a8038aa631b80ff58dc0038148922a15439e3b49"
    sha256 cellar: :any_skip_relocation, sonoma:         "6d4f2b6142c583d394da66a891c1b1f1aedd996a27a213aec7637d103f0b3302"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "598d981374461ef59eb101980315947da2ab36836a20dbdb9388f1bf71c6aa96"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "dd5fcd2b2545d835922733e7fc73282672952845c79d624638472bb9467d11cd"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.3/raxis-v0.3.3-darwin-arm64.tar.gz"
      sha256 "ec9f3eafa6b2921af2e4870c8c4afcf60b2bab30b6f046397f3437e04f331194"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.3/raxis-v0.3.3-darwin-x86_64.tar.gz"
      sha256 "362fc4416190fd5a4ff826e30bb1f537aa95d5e72ccaba3d9dd95553f7b1349d"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.3/raxis-v0.3.3-linux-arm64.tar.gz"
      sha256 "c98ca5c8b34a3d429e7e603ea7c5f756f05c157dfd1eb8120a827cc61a176b55"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.3/raxis-v0.3.3-linux-x86_64.tar.gz"
      sha256 "6d1af49535cc100ece77c8aa656bebb39426f77fa797cd33f067160b0dba3aed"
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
