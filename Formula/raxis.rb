# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.2.0"
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.2.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "dbc3b7436ec20a4fc43f66f15e6e5534dd59cb3ab8a559c99943f42a3dd45499"
    sha256 cellar: :any_skip_relocation, tahoe:          "80da2731e52f962d88f1fd3643311ba004fdfc3292739d2abc9c79cf2a90edff"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "01ce1eb272cc5aa847307e64e1c2520c8440f06fdf193913f80036b3b086920a"
    sha256 cellar: :any_skip_relocation, sequoia:        "99e00052c338d10ec687783d6ce8d949f651d483ec46462ae98c91154feb2f89"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "e2f08ec079a2e20dc47623cbb253ed8f66ce821129f5c37e9207edc5f2fe2cdc"
    sha256 cellar: :any_skip_relocation, sonoma:         "46b21e482069d79ef83686bd32a699fb68df8a87816f5d135c0781899166f9ad"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "9706616cfffc086cc3d83d2b78d688103fbd5040a5d30a6ecc290f1b1f3060f1"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "c2d8a35bdbad66476cfbebb73d525ca40cbae5413615da3cd2490f3feb13922c"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.0/raxis-v0.2.0-darwin-arm64.tar.gz"
      sha256 "94bcc855966c3f55944feeb19808afdb857ad3f66669abd075800355a50835e8"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.0/raxis-v0.2.0-darwin-x86_64.tar.gz"
      sha256 "92dde8cc954564145d56576aec18d1d1fb7c24d3dee162cf577ded6efb98dfa5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.0/raxis-v0.2.0-linux-arm64.tar.gz"
      sha256 "259f5e768a103952c932bf3350debac48cbe68789b88527548d8d1b964c32716"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.0/raxis-v0.2.0-linux-x86_64.tar.gz"
      sha256 "105cd052bd0b86ae5b74c9a4fc35ac2c6fae07ee7aa49b1cdd7a42e1fde122c5"
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
    run ["/bin/sh", "-c", "ulimit -n 4096 && exec #{opt_bin}/raxis-supervisor start"]
    keep_alive true
    environment_variables PATH: std_service_path_env,
                          RAXIS_INSTALL_DIR: opt_pkgshare.to_s,
                          RAXIS_DATA_DIR: (var/"lib/raxis").to_s,
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
        RAXIS_SUPERVISOR_AUTO_RESTART=1
        RAXIS_SUPERVISOR_REQUIRE_INITIALIZED_DATA_DIR=1

      The service launches raxis-supervisor, which launches and
      supervises raxis-kernel.
      It raises the launchd file-descriptor soft limit to 4096 before
      starting the kernel.

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
