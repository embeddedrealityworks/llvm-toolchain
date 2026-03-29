FROM debian:13-slim AS bob

RUN apt-get -y update ; \
  apt-get -y --no-install-recommends install \
  binutils-dev \
  bzip2 \
  ca-certificates \
  cmake \
  curl \
  git \
  gnupg \
  libedit-dev \
  libffi-dev \
  libncurses-dev \
  libpfm4-dev \
  libxml2-dev \
  libz3-dev \
  libzstd-dev \
  lsb-release \
  ninja-build \
  python3 \
  python3-dev \
  swig \
  zlib1g-dev ; \
  curl https://apt.llvm.org/llvm.sh -o /llvm.sh; \
  chmod +x /llvm.sh ; \
  /llvm.sh 22 all ; \
  apt-get clean ; \
  rm -rf /var/lib/apt/lists/*

RUN for f in /usr/bin/*-22 /usr/lib/llvm-22/bin/*; do \
  base=$(basename "$f"); \
  unsuffixed="${base%-22}"; \
  ln -sf "$f" "/usr/local/bin/${unsuffixed}"; \
  done

RUN git clone --depth 1 --branch release/22.x https://github.com/llvm/llvm-project.git /src

RUN mkdir -p /build ; \
  export CC=clang ; \
  export CXX=clang++ ; \
  cmake -G Ninja \
  -S /src/llvm \
  -B /build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/opt/toolchains/native \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb;polly;bolt" \
  -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind" \
  -DLLVM_TARGETS_TO_BUILD=Native \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLVM_ENABLE_PIC=ON \
  -DLLVM_ENABLE_RTTI=ON \
  -DLLVM_ENABLE_EH=ON \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLLVM_ENABLE_BINDINGS=OFF \
  -DLLVM_ENABLE_OCAMLDOC=OFF \
  -DLLVM_BUILD_DOCS=OFF \
  -DLLVM_ENABLE_SPHINX=OFF \
  -DLLVM_ENABLE_DOXYGEN=OFF \
  -DLLVM_BUILD_TESTS=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
  -DLLVM_INSTALL_UTILS=ON \
  -DLLVM_DISTRIBUTION_COMPONENTS="clang-resource-headers;clang;clang-check;clang-format;clang-scan-deps;lld;llvm-ar;llvm-cov;llvm-cxxfilt;llvm-nm;llvm-objcopy;llvm-profdata;llvm-ranlib;llvm-readobj;llvm-size;llvm-strings;llvm-strip;llvm-symbolizer;LTO;cxx;cxxabi;unwind;compiler-rt" \
  -DLLVM_ENABLE_FFI=ON \
  -DLLVM_ENABLE_Z3_SOLVER=ON \
  -DLLVM_ENABLE_LIBPFM=ON \
  -DLLVM_LINK_LLVM_DYLIB=OFF \
  -DLLVM_BINUTILS_INCDIR=/usr/include \
  -DCLANG_LINK_CLANG_DYLIB=OFF \
  -DCLANG_DEFAULT_LINKER=lld \
  -DCLANG_DEFAULT_RTLIB=compiler-rt \
  -DCLANG_DEFAULT_UNWINDLIB=libunwind \
  -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
  -DCLANG_DEFAULT_PIE_ON_LINUX=ON \
  -DLIBCXX_USE_COMPILER_RT=ON \
  -DLIBCXXABI_USE_COMPILER_RT=ON \
  -DLIBCXX_INSTALL_MODULES=ON \
  -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
  -DLLVM_VERSION_SUFFIX= ; \
  cd /build ; \
  ninja -j$(nproc) ; \
  ninja install-distribution

FROM debian:13-slim

LABEL com.embeddedreality.llvm-toolchain.version="22.x"

COPY --from=bob /opt/toolchains/native /opt/toolchains/native
RUN apt-get -y update ; \
  apt-get -y --no-install-recommends install \
  ca-certificates \
  apt-get clean ; \
  rm -rf /var/lib/apt/lists/* ; \
  useradd -ms /bin/bash bob

USER bob
ENV PATH="$PATH:/opt/toolchains/native/bin"
