# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

require "json"

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.3.1"

  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.3.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "a41ce5418b2a9fba5f6e7f38cebe86ab8b7cc1de9faa6c3a3bef285f8fe96d04"
    sha256 cellar: :any_skip_relocation, tahoe:          "1c08af8707897b350a4cb9bdcc08d6faa6e25baac9d8221a1abc936d01f81957"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "3892b21531a7b1132c3e6422d90d51aa926d63789bdccc24e492d07521b386f9"
    sha256 cellar: :any_skip_relocation, sequoia:        "32971ee4f7339b35d3c9f9e390948db6c5af794a5ce4a8ca6f1edc63ca5f2e79"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "19838218b61c0292c068e4909caa1f6238a12f751ebd86f132657f7bc84001a8"
    sha256 cellar: :any_skip_relocation, sonoma:         "23b954c163ebf6408da3fb14dbbff9269a55f19da94eb511a0e2eccc484b82ef"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "6a737aa11eaafa4e08fc2414463020ce930d36335a014f247ac7e9897a74799d"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "250f95afd692c63fc07586b93ade6a7ae1c3e5dfc367d3b334913e81e9cfe43a"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.1/raxis-v0.3.1-darwin-arm64.tar.gz"
      sha256 "cba58c51bf3d26afc405ae480c13794ceba32df18ad1ea4fe2489667eabe18c9"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.1/raxis-v0.3.1-darwin-x86_64.tar.gz"
      sha256 "01b8dcea44e58349df784274e88fc52809996827f2f6997e11f1235a0fbde0d7"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.1/raxis-v0.3.1-linux-arm64.tar.gz"
      sha256 "07e68e79b4c2c7fd29c3a0970a2f9c8b1bc3b9d58f316b580e5053b7ac769220"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.3.1/raxis-v0.3.1-linux-x86_64.tar.gz"
      sha256 "2ecb8ea7ec729d26f092ab8b07363f4bf180f4f8df5d2c4280aefa63c98a41ff"
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
