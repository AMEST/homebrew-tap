class MongoTui < Formula
  desc "Terminal UI client for MongoDB"
  homepage "https://github.com/AMEST/mongo-tui"
  url "https://github.com/AMEST/mongo-tui/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "f36b2d24b412de82650d201040c9f4cbd158aa2eb28fc43f3358c9a2d1e327a9"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "dotnet@10" => :build
  depends_on arch: :arm64
  depends_on macos: :sonoma
  depends_on "mongodb/brew/mongodb-database-tools"
  depends_on "mongosh"

  def project_path
    "src/MongoTui.TUI/MongoTui.TUI.csproj"
  end

  def ensure_dotnet!
    return if which("dotnet")

    odie ".NET SDK 10 was not found (expected from the dotnet@10 build dependency)."
  end

  def fetch
    ensure_dotnet!
    ENV["DOTNET_CLI_TELEMETRY_OPTOUT"] = "1"
    ENV["DOTNET_GENERATE_ASPNET_CERTIFICATE"] = "false"
    system "dotnet", "restore", project_path,
           "--runtime", "osx-arm64",
           "--disable-build-servers",
           "-p:Configuration=Release",
           "-p:SelfContained=true",
           "-p:Version=#{version}"
  end

  def install
    ensure_dotnet!
    ENV["DOTNET_CLI_TELEMETRY_OPTOUT"] = "1"
    ENV["DOTNET_GENERATE_ASPNET_CERTIFICATE"] = "false"
    system "dotnet", "publish", project_path,
           "--configuration", "Release",
           "--runtime", "osx-arm64",
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
