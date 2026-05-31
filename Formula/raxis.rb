# Auto-generated from raxis/release/templates/raxis.rb.tmpl
# by .github/workflows/release.yml. Do NOT hand-edit the rendered
# formula in the tap repository; the next release overwrites it.

class Raxis < Formula
  desc     "Runtime Attestation eXchange for Intelligent Systems"
  homepage "https://raxis.io"
  version  "0.2.4"
  license  "SSPL-1.0"

  bottle do
    root_url "https://github.com/chika5105/raxis/releases/download/v0.2.4"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "df17ca3d47b4efbe64978548d5f1cd16ce877f80e2ed962e62232d1c82cd95df"
    sha256 cellar: :any_skip_relocation, tahoe:          "b5c1fff71590a4304b54aefbfb2187165af49992e9ec7e7d9f9768fd3127affa"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "9155bd885f02c1219746636fa8d58163bf58c2e80d606abd4d4206846b1c1bca"
    sha256 cellar: :any_skip_relocation, sequoia:        "d5453012215ee76344028ae5dc5d262e89a3afaf0598b52b3303e941191ddd2e"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "afe02aef21532639aeed66177cedef381ab90595be8811f6e7dc49ad6ae1be56"
    sha256 cellar: :any_skip_relocation, sonoma:         "3d3e4f2055ddf770c33f947aaabb16e809904a0a1aa6984f269148899efefee6"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "4c9ee74708d7e8f55ba04504788daacba424cc6df555314989660724d9357b1e"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "c9797819d496d655349b406c37604535f6d7808e9f35926ed8cc89f0a4e78553"
  end

  on_macos do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.4/raxis-v0.2.4-darwin-arm64.tar.gz"
      sha256 "6757a5e9f6f7fc2894e5a65cbe1cb64dcd19dd1efe57b0244c1666a440cf83ef"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.4/raxis-v0.2.4-darwin-x86_64.tar.gz"
      sha256 "75b2413de6a11ae6b091dd9ca9612a7370e127a726c09bb1490676bc672daedc"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.4/raxis-v0.2.4-linux-arm64.tar.gz"
      sha256 "038e7cbe437024e34308182e269c02652daf8f053f975898d7750b5b03485dee"
    end
    on_intel do
      url "https://github.com/chika5105/raxis/releases/download/v0.2.4/raxis-v0.2.4-linux-x86_64.tar.gz"
      sha256 "f127fa55ddf570a23552c01df7a73b8727df0a55245b42173a2782b415bfb134"
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
