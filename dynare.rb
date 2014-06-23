require "formula"

class Dynare < Formula
  homepage "http://www.dynare.org"
  url "https://www.dynare.org/release/source/dynare-4.4.2.tar.xz"
  sha1 "be2c6da37f95dc1469edba2759ee1ad05401a6f3"

  option "with-matlab=</full/path/to/MATLAB_VER.app>", \
  "Build mex files for Matlab"
  option "with-matlab-version=<VER>", \
  "The version of Matlab pointed to by --with-matlab. E.g. 8.2"
  option "with-doc", "Build Dynare documentation"
  option "without-check", "Disable build-time checking (not recommended)"

  depends_on "octave"=> :recommended
  depends_on :fortran
  depends_on "fftw"
  depends_on "gsl"
  depends_on "libmatio"
  depends_on "matlab2tikz"
  depends_on "graphicsmagick" if build.with? "octave"
  depends_on "xz" => :build
  depends_on "boost" => :build
  depends_on "homebrew/science/slicot" => \
  ("with-default-integer-8" if build.with? "matlab")
  depends_on :tex => :build if build.with? "doc"
  depends_on "doxygen" => :build if build.with? "doc"

  def patches
    # As installation is different between platforms,
    # create patch to modify .m file that sets paths
    "https://gist.github.com/houtanb/9069576/raw/7e261f4f00be23b3bbcae5a7193533cb57d4983d/dynare_config.patch"
  end

  def install
    args=%W[
            --disable-debug
            --disable-dependency-tracking
            --disable-silent-rules
            --prefix=#{prefix}
    ]
    matlab_path = ARGV.value("with-matlab") || ""
    matlab_version = ARGV.value("with-matlab-version") || ""
    if matlab_path.empty? || matlab_version.empty?
      args << "--disable-matlab"
    else
      args << "--with-matlab=#{matlab_path}"
      args << "MATLAB_VERSION=#{matlab_version}"
    end
    args << "--disable-octave" if build.without? "octave"

    system "./configure", *args
    system "make"

    if build.with? "doc"
      inreplace "doc/Makefile", \
      "$(TEXI2DVI) $(AM_V_texinfo) --build-dir=$(@:.dvi=.t2d) -o $@ " \
      "$(AM_V_texidevnull)", \
      "$(TEXI2DVI) $(AM_V_texinfo) --build-dir=$(@:.dvi=.t2d) " \
      "$(AM_V_texidevnull)"
      system "make", "pdf"
    end

    # make install was never set up on Dynare,
    # hence install necessary files vio Homebrew
    # Install Preprocessor
    (lib/"dynare/matlab").install "preprocessor/dynare_m"

    # Install Octave mex/oct files
    (lib/"dynare/mex/octave").install \
    "mex/build/octave/kronecker/A_times_B_kronecker_C.mex", \
    "mex/build/octave/block_kalman_filter/block_kalman_filter.mex", \
    "mex/build/octave/bytecode/bytecode.mex", \
    "mex/build/octave/dynare_simul_/dynare_simul_.mex", \
    "mex/build/octave/gensylv/gensylv.mex", \
    "mex/build/octave/k_order_perturbation/k_order_perturbation.mex", \
    "mex/build/octave/kalman_steady_state/kalman_steady_state.mex", \
    "mex/build/octave/local_state_space_iterations/local_state_space_iteration_2.mex", \
    "mex/build/octave/mjdgges/mjdgges.mex", \
    "mex/build/octave/ms_sbvar/ms_sbvar_command_line.mex", \
    "mex/build/octave/ms_sbvar/ms_sbvar_create_init_file.mex", \
    "mex/build/octave/ordschur/ordschur.oct", \
    "mex/build/octave/sobol/qmc_sequence.mex", \
    "mex/build/octave/qzcomplex/qzcomplex.oct", \
    "mex/build/octave/kronecker/sparse_hessian_times_B_kronecker_C.mex" \
    if build.with? "octave"

    # Install Matlab mex files
    (lib/"dynare/mex/matlab").install \
    Dir.glob("mex/build/matlab/kronecker/A_times_B_kronecker_C.mex*"), \
    Dir.glob("mex/build/matlab/block_kalman_filter/block_kalman_filter.mex*"), \
    Dir.glob("mex/build/matlab/bytecode/bytecode.mex*"), \
    Dir.glob("mex/build/matlab/dynare_simul_/dynare_simul_.mex*"), \
    Dir.glob("mex/build/matlab/gensylv/gensylv.mex*"), \
    Dir.glob("mex/build/matlab/k_order_perturbation/k_order_perturbation.mex*"), \
    Dir.glob("mex/build/matlab/kalman_steady_state/kalman_steady_state.mex*"), \
    Dir.glob("mex/build/matlab/local_state_space_iterations/local_state_space_iteration_2.mex*"), \
    Dir.glob("mex/build/matlab/mjdgges/mjdgges.mex*"), \
    Dir.glob("mex/build/matlab/ms_sbvar/ms_sbvar_command_line.mex*"), \
    Dir.glob("mex/build/matlab/ms_sbvar/ms_sbvar_create_init_file.mex*"), \
    Dir.glob("mex/build/matlab/sobol/qmc_sequence.mex*"), \
    Dir.glob("mex/build/matlab/kronecker/sparse_hessian_times_B_kronecker_C.mex*") \
    if (!matlab_version.empty? && !matlab_version.empty?)

    # Install Matlab/Octave m files
    (share/"dynare/").install "matlab"
    (share/"dynare/contrib/ms-sbvar/").install "contrib/ms-sbvar/TZcode"

    # Install dynare++ executable
    bin.install("dynare++/src/dynare++")

    # Install examples
    (share/"dynare/").install "examples"

    # Install documentation
    doc.install "doc/dynare.pdf", "doc/bvar-a-la-sims.pdf", "doc/dr.pdf", \
    "doc/guide.pdf", "doc/macroprocessor/macroprocessor.pdf", \
    "doc/parallel/parallel.pdf", "doc/preprocessor/preprocessor.pdf", \
    "doc/userguide/UserGuide.pdf", "doc/gsa/gsa.pdf" \
    if build.with? "doc"
  end

  test do
    copy("#{share}/dynare/examples/bkk.mod", testpath)
    if build.with? "octave"
      system "octave --no-gui -H " \
      "--path #{HOMEBREW_PREFIX}/share/dynare/matlab " \
      "--eval 'dynare bkk.mod console'"
    end
    matlab_path = ARGV.value("with-matlab") || ""
    if !matlab_path.empty?
      system "#{matlab_path}/bin/matlab -nosplash -nodisplay " \
      "-r 'addpath #{HOMEBREW_PREFIX}/share/dynare/matlab; " \
      "dynare bkk.mod console'"
    end
  end

  def caveats
    s = <<-EOS.undent
    To get started with dynare, open Matlab or Octave and type:

            addpath #{HOMEBREW_PREFIX}/share/dynare/matlab
    EOS
  end
end
