set -e

TAG="10.0.0-rc5"
TUG="10.0.0rc5"
OUT="/opt/chain/${TAG}"
THREADS=8
GIT="https://github.com/llvm/llvm-project/releases/download/llvmorg-${TAG}"

mkdir -p $OUT

get(){
  [ ! -f "$1" ] && wget ${GIT}/$1
  tar xf $1
}

mkdir -p llvm && cd llvm

# get llvm-${TUG}.src.tar.xz
# get clang-${TUG}.src.tar.xz
# get clang-tools-extra-${TUG}.src.tar.xz
# get compiler-rt-${TUG}.src.tar.xz

# mv llvm-${TUG}.src llvm
# mv clang-${TUG}.src llvm/tools/clang
# mv clang-tools-extra-${TUG}.src llvm/tools/clang/tools/extra
# mv compiler-rt-${TUG}.src llvm/projects/compiler-rt

export CC=/opt/chain/gcc-9.2.0/bin/gcc
export CXX=/opt/chain/gcc-9.2.0/bin/g++

mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUT -DCMAKE_CXX_FLAGS="-g3 -rdynamic -O3 -march=native -fPIC" ../llvm
make -j$THREADS 1> /dev/null
make install 1> /dev/null
