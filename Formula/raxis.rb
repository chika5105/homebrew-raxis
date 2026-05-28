# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.2.3"
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.2.3"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "dcd52034946d9fa7f1e8ab8a4c48fe4d25738b0069422291feeab2c57a8bddc1"
    sha256 cellar: :any_skip_relocation, tahoe:          "f6c58055d819fcb3dec0dbde33b4fe3d6d183024c6c32a7abe3f8d1b760d0c85"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "8deaac724e42a4684b44ed3ce3f08cecf4eca340d59f035246ab880d9b1c1ee5"
    sha256 cellar: :any_skip_relocation, sequoia:        "7184dd35d086bddb0bd1a8ce4e431ff0d32d7825defc04d20e2dceab68e8531f"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "a3081e793e14e02bd83ac13f00bec082564c67f285da352aa11ce42b1cfed195"
    sha256 cellar: :any_skip_relocation, sonoma:         "6463a43c459c7c84bdcb9e2f9ba79576b69f5a481554b325769673f1149c1847"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "c681f896e99a17963f332c62a766362b3691f8c599bc852ea836d29920fca05a"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "b4ce0a6a904c54d2ef3925cc6892c8672e69703751cce1719285a728e9b92cc7"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.3/raxis-v0.2.3-darwin-arm64.tar.gz"
      sha256 "04d860c8a582c6503a7a8cb91a2ba320c5724f36244181fda596b8ae0c9c3241"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.3/raxis-v0.2.3-darwin-x86_64.tar.gz"
      sha256 "2146281c40f23604bb1701b41c92430d13547a96f8aca44048ebf8e3cc3c8cfe"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.3/raxis-v0.2.3-linux-arm64.tar.gz"
      sha256 "c5187d994c7650ef5d024a96c4dbad974b4995f0484a48be340b1e1e7a37d740"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.3/raxis-v0.2.3-linux-x86_64.tar.gz"
      sha256 "bdb158205a0e1a6d0170bc698ee9933c1f967f573cc1f0a06f6daaab86a65ce4"
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
