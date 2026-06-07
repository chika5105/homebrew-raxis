# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.2.6"

  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.2.6"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "b8839a6eb3124f73c34e9a1e3d2490094208bd83def3f4fad5c1c361c1fd3e56"
    sha256 cellar: :any_skip_relocation, tahoe:          "e9ea140dfa1e1c9810efa32a57ffff21164d49757b57ad09c8c979f8e0849e2e"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "c8e6d6ef2fe2aec8190530f49b2e5e75091cf17f8af8c97d9c778c7d9ef60b3f"
    sha256 cellar: :any_skip_relocation, sequoia:        "ca1181dde6523da8239fecb0ba382fc73d62a578363a4419e6369ad0d696603f"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "85f0522ac2c98749c92c39d39065cff2b556e2248a540629bb3a3c2d6b59c426"
    sha256 cellar: :any_skip_relocation, sonoma:         "13f4ddb34f2f804f16bcca55648a5b8d885288fb7c7e2be18e3febbda2117873"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "9ef552b14cc8014a7f1da5aae5f47de45c44e63fd3d8fff441478a0438f29c2c"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "868baf61e11037f612d37663c750db71afe5c6786d4bfd8bfde6a1926b79900d"
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
