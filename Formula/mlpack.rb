class Mlpack < Formula
  desc "Scalable C++ machine learning library"
  homepage "https://www.mlpack.org"
  url "https://mlpack.org/files/mlpack-3.3.2.tar.gz"
  sha256 "11904a39a7e34ee66028292fd054afb460eacd07ec5e6c63789aba117e4d854c"
  revision 1

  bottle do
    cellar :any
    sha256 "27c59633a936fd31833c5c6f2043508472150c14ab7bc81861a6c3cec0da0c9f" => :catalina
    sha256 "02258bb1646b2fc8aa99e1b4033b69b00b3fd70d34be55090d8c593191c8fb66" => :mojave
    sha256 "eebd7bba90143afd6a23b44e1b158387c5b68191bcd1f94475f46c5e22a422dd" => :high_sierra
  end

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "pkg-config" => :build
  depends_on "armadillo"
  depends_on "boost"
  depends_on "ensmallen"
  depends_on "graphviz"

  resource "stb_image" do
    url "https://mlpack.org/files/stb-2.22/stb_image.h"
    sha256 "0e28238d865510073b5740ae8eba8cd8032cc5b25f94e0f7505fac8036864909"
  end

  resource "stb_image_write" do
    url "https://mlpack.org/files/stb-1.13/stb_image_write.h"
    sha256 "0e8b3d80bc6eb8fdb64abc4db9fec608b489bc73418eaf14beda102a0699a4c9"
  end

  def install
    resources.each do |r|
      r.stage do
        (include/"stb").install "#{r.name}.h"
      end
    end
    cmake_args = std_cmake_args + %W[
      -DDEBUG=OFF
      -DPROFILE=OFF
      -DBUILD_TESTS=OFF
      -DDISABLE_DOWNLOADS=ON
      -DARMADILLO_INCLUDE_DIR=#{Formula["armadillo"].opt_include}
      -DENSMALLEN_INCLUDE_DIR=#{Formula["ensmallen"].opt_include}
      -DARMADILLO_LIBRARY=#{Formula["armadillo"].opt_lib}/libarmadillo.dylib
      -DSTB_IMAGE_INCLUDE_DIR=#{include/"stb"}
    ]
    mkdir "build" do
      system "cmake", "..", *cmake_args
      system "make", "install"
    end
    doc.install Dir["doc/*"]
    (pkgshare/"tests").install "src/mlpack/tests/data" # Includes test data.
  end

  test do
    cd testpath do
      system "#{bin}/mlpack_knn",
        "-r", "#{pkgshare}/tests/data/GroupLensSmall.csv",
        "-n", "neighbors.csv",
        "-d", "distances.csv",
        "-k", "5", "-v"
    end

    (testpath/"test.cpp").write <<-EOS
      #include <mlpack/core.hpp>

      using namespace mlpack;

      int main(int argc, char** argv) {
        Log::Debug << "Compiled with debugging symbols." << std::endl;
        Log::Info << "Some test informational output." << std::endl;
        Log::Warn << "A false alarm!" << std::endl;
      }
    EOS
    system ENV.cxx, "test.cpp", "-std=c++11", "-I#{include}", "-I#{Formula["armadillo"].opt_lib}/libarmadillo",
                    "-L#{lib}", "-lmlpack", "-o", "test"
    system "./test", "--verbose"
  end
end
