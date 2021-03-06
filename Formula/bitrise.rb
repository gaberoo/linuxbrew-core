class Bitrise < Formula
  desc "Command-line automation tool"
  homepage "https://github.com/bitrise-io/bitrise"
  url "https://github.com/bitrise-io/bitrise/archive/1.30.0.tar.gz"
  sha256 "8925dff4ccee7e129456cf17a5e4ae23dea183acbf195cffd7b6410ffbc1a33c"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles"
    cellar :any_skip_relocation
    sha256 "641ead00c18470aa56fcde684653c7f4c97753e15c2189435477b593606f8a84" => :mojave
    sha256 "00e3c6cef72f2068bec607c1abe7cc7401151044dc395fec3a657f2064aa36cf" => :high_sierra
    sha256 "49a474df1899ec9984c89b1dd7904283786fef8b36b2fa54f200192d8fe44592" => :sierra
    sha256 "6c7fc01bd90a59ea38572ea18b231c1a1ffd51befe29e975954cf56f11ecac68" => :x86_64_linux
  end

  depends_on "go" => :build
  depends_on "rsync" => :test

  def install
    ENV["GOPATH"] = buildpath

    # Install bitrise
    bitrise_go_path = buildpath/"src/github.com/bitrise-io/bitrise"
    bitrise_go_path.install Dir["*"]

    cd bitrise_go_path do
      prefix.install_metafiles

      system "go", "build", "-o", bin/"bitrise"
    end
  end

  test do
    (testpath/"bitrise.yml").write <<~EOS
      format_version: 1.3.1
      default_step_lib_source: https://github.com/bitrise-io/bitrise-steplib.git
      workflows:
        test_wf:
          steps:
          - script:
              inputs:
              - content: printf 'Test - OK' > brew.test.file
    EOS

    system "#{bin}/bitrise", "setup"
    system "#{bin}/bitrise", "run", "test_wf"
    assert_equal "Test - OK", (testpath/"brew.test.file").read.chomp
  end
end
