class GoAT111 < Formula
  desc "Go programming environment (1.11)"
  homepage "https://golang.org"
  url "https://dl.google.com/go/go1.11.6.src.tar.gz"
  mirror "https://fossies.org/linux/misc/go1.11.6.src.tar.gz"
  sha256 "a96da1425dcbec094736033a8a416316547f8100ab4b72c31d4824d761d3e133"

  bottle do
    sha256 "ea7bc6953386d6c918bc4cb04b2ae9b9c6630c408690abccf3a183b98121550f" => :mojave
    sha256 "77ed9c049a790f3ab15d38051deca77b68f8666a225e881015fe5f56734ab6ec" => :high_sierra
    sha256 "6010340eb598272a6b256e9e2287c6cfea2d2e20ff97d548d7aa1962237d7d56" => :sierra
    sha256 "b7aead0a6c15dae2e6f4b963b860842f2e05f7a1fdccb8a3c92403872250c8f6" => :x86_64_linux
  end

  keg_only :versioned_formula

  depends_on :macos => :yosemite

  resource "gotools" do
    url "https://go.googlesource.com/tools.git",
        :branch => "release-branch.go1.11"
  end

  # Don't update this unless this version cannot bootstrap the new version.
  resource "gobootstrap" do
    if OS.mac?
      url "https://storage.googleapis.com/golang/go1.7.darwin-amd64.tar.gz"
      sha256 "51d905e0b43b3d0ed41aaf23e19001ab4bc3f96c3ca134b48f7892485fc52961"
    elsif OS.linux?
      url "https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz"
      sha256 "702ad90f705365227e902b42d91dd1a40e48ca7f67a2f4b2fd052aaa4295cd95"
    end
    version "1.7"
  end

  def install
    ENV["CGO_ENABLED"] = "1" unless OS.mac?
    (buildpath/"gobootstrap").install resource("gobootstrap")
    ENV["GOROOT_BOOTSTRAP"] = buildpath/"gobootstrap"

    cd "src" do
      ENV["GOROOT_FINAL"] = libexec
      ENV["GOOS"]         = OS.mac? ? "darwin" : "linux"
      system "./make.bash", "--no-clean"
    end

    (buildpath/"pkg/obj").rmtree
    rm_rf "gobootstrap" # Bootstrap not required beyond compile.
    libexec.install Dir["*"]
    bin.install_symlink Dir[libexec/"bin/go*"]

    system bin/"go", "install", "-race", "std"

    # Build and install godoc
    ENV.prepend_path "PATH", bin
    ENV["GO111MODULE"] = "on"
    ENV["GOPATH"] = buildpath
    (buildpath/"src/golang.org/x/tools").install resource("gotools")
    cd "src/golang.org/x/tools/cmd/godoc/" do
      system "go", "build"
      (libexec/"bin").install "godoc"
    end
    bin.install_symlink libexec/"bin/godoc"
  end

  test do
    (testpath/"hello.go").write <<~EOS
      package main

      import "fmt"

      func main() {
          fmt.Println("Hello World")
      }
    EOS
    # Run go fmt check for no errors then run the program.
    # This is a a bare minimum of go working as it uses fmt, build, and run.
    system bin/"go", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/go run hello.go")

    # godoc was installed
    assert_predicate libexec/"bin/godoc", :exist?
    assert_predicate libexec/"bin/godoc", :executable?

    ENV["GOOS"] = "freebsd"
    system bin/"go", "build", "hello.go"
  end
end
