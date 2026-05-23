# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.1.0"
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.1.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "3e2cb10509035056ee8ecf683eaec14e9cbdb3aec54805c2e181c2db087dac6a"
    sha256 cellar: :any_skip_relocation, tahoe:          "09f9a8b08b2625f46f9461e52eeaa97c0669f5b069c0e1d772ce2b7a3f97317e"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "28d28284f52523899b147309f41971091f03b9f6a7cf9010892a7c5a9ae083d5"
    sha256 cellar: :any_skip_relocation, sequoia:        "55ba2c41e683f400afb54537bd4eef9fb3cbcd0a3517774270cf43055c0aaac7"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "cf792b7a62357b4a453caa025aaf45c889af1d9c3a82efea0bea99eb82234dc9"
    sha256 cellar: :any_skip_relocation, sonoma:         "dbc7aba4f3af4d827c749b38b8dc1b4ef0a2dcee69c1a0c819c4af8e90864783"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "b0bdc8b85304eb3d7c995a710d96525503561362f58212155b34ee59e08ad43e"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "50a9c62897d1efbdaa7952956e83052caa9f360b9771d707585393529928c138"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.0/raxis-v0.1.0-darwin-arm64.tar.gz"
      sha256 "ec61da18ae50eff7909cc857264f1531c725e341fbdf7167c06deeef93eb2b30"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.0/raxis-v0.1.0-darwin-x86_64.tar.gz"
      sha256 "e538f0dcc7be6e55d4beb751eccf1bbd8ba74c4b364795fa1e63ec737d597d1b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.0/raxis-v0.1.0-linux-arm64.tar.gz"
      sha256 "0ea78433c596ad5237d1ea455f32459e5dfe8e5785cca9aa7fa0f7e150487276"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.1.0/raxis-v0.1.0-linux-x86_64.tar.gz"
      sha256 "c2a696658c1f1aaef25fd1f4daa0229e3bfcbc798f3a3321303200b1173e9e4a"
    end
  end

  def install
    bin.install "bin/raxis-kernel"
    bin.install "bin/raxis-cli"
    bin.install "bin/raxis"
    bin.install "bin/raxis-gateway"
    bin.install "bin/raxis-otel-pusher"
    bin.install "bin/raxis-supervisor"
    bin.install "bin/raxis-orchestrator"
    bin.install "bin/raxis-executor"
    bin.install "bin/raxis-reviewer"
    bin.install "bin/raxis-tproxy"

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
    run [opt_bin/"raxis-supervisor", "start"]
    keep_alive true
    environment_variables RAXIS_INSTALL_DIR: opt_pkgshare.to_s,
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

      Dashboard static bundle:
        #{opt_pkgshare}/dashboard
      To serve it, configure policy.toml with:
        [dashboard]
        static_dir = "#{opt_pkgshare}/dashboard"

      Start the kernel with:
        brew services start raxis

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
