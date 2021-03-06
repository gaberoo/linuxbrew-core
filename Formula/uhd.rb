class Uhd < Formula
  desc "Hardware driver for all USRP devices"
  homepage "https://files.ettus.com/manual/"
  url "https://github.com/EttusResearch/uhd/archive/v3.14.0.0.tar.gz"
  sha256 "612bcc4e857e126c2e1ace98618816209665b20c4136c9e987c67511661715df"
  head "https://github.com/EttusResearch/uhd.git"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles"
    sha256 "3eacbff6e35b276dda53c2bee7cd46cab690258c2d723ff7dac89df2f8d99c83" => :mojave
    sha256 "ed187800f2255414f237d93cfc3852433ebc17d6920c18ece82d03f3e37ef865" => :high_sierra
    sha256 "dec154f562fa22f2aecedb86ff836d7e8e8713eb06f5073be8805c1fe9c83f1c" => :sierra
    sha256 "222902353d6942177e45edef3d3f0dd066a3d6e77237cd05c6370bbc45a87200" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "boost"
  depends_on "libusb"
  depends_on "python"

  resource "Mako" do
    url "https://files.pythonhosted.org/packages/eb/f3/67579bb486517c0d49547f9697e36582cd19dafb5df9e687ed8e22de57fa/Mako-1.0.7.tar.gz"
    sha256 "4e02fde57bd4abb5ec400181e4c314f56ac3e49ba4fb8b0d50bba18cb27d25ae"
  end

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j1" if ENV["CIRCLECI"]

    xy = Language::Python.major_minor_version "python3"
    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python#{xy}/site-packages"

    resource("Mako").stage do
      system "python3", *Language::Python.setup_install_args(libexec/"vendor")
    end

    mkdir "host/build" do
      system "cmake", "..", *std_cmake_args, "-DENABLE_PYTHON3=ON"
      system "make"
      system "make", "test"
      system "make", "install"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/uhd_config_info --version")
  end
end
