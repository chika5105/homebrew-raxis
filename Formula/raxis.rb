# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.1.3"
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.1.3"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "1d1b0a81a04b02ac289b28d6a1b7818d0e6911cbcf38c4d91f0e6107dc593fd4"
    sha256 cellar: :any_skip_relocation, tahoe:          "e9c28cdebc4d9589677a92e309bef28573c1efff85bec4dc11fdba6ac2340031"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "48f3ca39eef9f94038217ceda884185a477ea63006b1be3bc4c853c3fa4d8db1"
    sha256 cellar: :any_skip_relocation, sequoia:        "668ee5289d96da80130ca042cf112f8c43d873920a58d59906a080ab46364e42"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "e92ca3e15b8c8f41cf54602f1b259a055feb0754ce58522fdbed4ec4cf65ef7c"
    sha256 cellar: :any_skip_relocation, sonoma:         "40d85101c0c55438849763fcb2deed1e9eb30c41a0831869ee1164d1619770bf"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "9220249dc4e8e2e3fa66e0ccc371718aa5e529370114435dc85ee21c169c9c63"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "9d2b90dcc4b5522955d6539bf67d162eb0c76c591aaa67e1d25f2f7975624bde"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.3/raxis-v0.1.3-darwin-arm64.tar.gz"
      sha256 "fca2a593543a0c3ede661bbbc8901b376e5773066dec893e5bf16a9ed2a237dd"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.3/raxis-v0.1.3-darwin-x86_64.tar.gz"
      sha256 "5a13d3126692f608c423a3d625e164739830512eaf2e2795b09eaa42a730a78c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.3/raxis-v0.1.3-linux-arm64.tar.gz"
      sha256 "db16b93460a22cbdc8ec9535bf7951031b522522cda5475a8aa912d27cdc9231"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.3/raxis-v0.1.3-linux-x86_64.tar.gz"
      sha256 "eaad5654ce9427ecc0fb423d4e08a6d90b01b7d4e84523a414207b140e1a090b"
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
    run ["/bin/sh", "-c", "ulimit -n 4096 && exec #{opt_bin}/raxis-supervisor start"]
    keep_alive true
    environment_variables PATH: std_service_path_env,
                          RAXIS_INSTALL_DIR: opt_pkgshare.to_s,
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
      It raises the launchd file-descriptor soft limit to 4096 before
      starting the kernel.

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
