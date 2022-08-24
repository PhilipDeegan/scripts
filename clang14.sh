

TAG="14.0.6"
TUG="14.0.6"
OUT="/opt/chain/clang_${TAG}"
THREADS=8
GIT="https://github.com/llvm/llvm-project/releases/download/llvmorg-${TAG}"

set -ex

mkdir -p $OUT

get(){
  [ ! -f "$1" ] && wget ${GIT}/$1
  ls -l $1
  echo $PWD
  tar xf $1
}

cd ~/
mkdir -p llvm && cd llvm

get llvm-${TUG}.src.tar.xz
get clang-${TUG}.src.tar.xz
get clang-tools-extra-${TUG}.src.tar.xz
get compiler-rt-${TUG}.src.tar.xz

mv llvm-${TUG}.src llvm
mv clang-${TUG}.src llvm/tools/clang
mv clang-tools-extra-${TUG}.src llvm/tools/clang/tools/extra
mv compiler-rt-${TUG}.src llvm/projects/compiler-rt


CMAKE_FLAGS=-DLLVM_INCLUDE_BENCHMARKS=OFF

mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUT ${CMAKE_FLAGS} ../llvm
make -j$THREADS 1> /dev/null
make install 1> /dev/null

cd ~/
rm -rf llvm

