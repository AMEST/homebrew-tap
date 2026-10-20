class MongoTui < Formula
  desc "Terminal UI client for MongoDB"
  homepage "https://github.com/AMEST/mongo-tui"
  url "https://github.com/AMEST/mongo-tui/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "a8d1a781b25914a8f3b9997ff4b399a6930ef2f89d28202efa466f79339a01b4"
  license "MIT"

  depends_on "dotnet@10" => :build
  depends_on macos: :sonoma
  depends_on "mongodb/brew/mongodb-database-tools"
  depends_on "mongosh"

  def project_path
    "src/MongoTui.TUI/MongoTui.TUI.csproj"
  end

  def runtime_id
    Hardware::CPU.arm? ? "osx-arm64" : "osx-x64"
  end

  def fetch
    ENV["DOTNET_CLI_TELEMETRY_OPTOUT"] = "1"
    ENV["DOTNET_GENERATE_ASPNET_CERTIFICATE"] = "false"
    system "dotnet", "restore", project_path,
           "--runtime", runtime_id,
           "--disable-build-servers",
           "-p:Configuration=Release",
           "-p:SelfContained=true",
           "-p:Version=#{version}"
  end

  def install
    ENV["DOTNET_CLI_TELEMETRY_OPTOUT"] = "1"
    ENV["DOTNET_GENERATE_ASPNET_CERTIFICATE"] = "false"
    system "dotnet", "publish", project_path,
           "--configuration", "Release",
           "--runtime", runtime_id,
           "--self-contained", "true",
           "--no-restore",
           "--disable-build-servers",
           "-p:Version=#{version}",
           "--output", libexec

    bin.write_exec_script libexec/"mongo-tui"
  end

  def caveats
    <<~EOS
      SSH connections require OpenSSH 8.4 or newer in PATH.
    EOS
  end

  test do
    ENV.delete("MONGOTUI_ASKPASS_PIPE")
    output = shell_output("#{bin}/mongo-tui --version")
    assert_equal version.to_s, output.lines.first.strip
    assert_match "MIT License", output
    assert_path_exists libexec/"libe_sqlite3.dylib"
    assert_path_exists libexec/"libonigwrap.dylib"
    system "mongoimport", "--version"
    system "mongoexport", "--version"
  end
end
