set -e

TAG="9.0.1"
OUT=/opt/chain/clang9
THREADS=6
mkdir -p $OUT

GIT="https://github.com/llvm/llvm-project/releases/download/llvmorg-${TAG}/"

get(){
  [ ! -f "$1" ] && wget ${GIT}/$1
  tar xf $1
}

mkdir -p llvm && cd llvm

get llvm-${TAG}.src.tar.xz
get clang-${TAG}.src.tar.xz
get clang-tools-extra-${TAG}.src.tar.xz
get compiler-rt-${TAG}.src.tar.xz

# mv llvm-${TAG}.src llvm
# mv clang-${TAG}.src llvm/tools/clang
# mv clang-tools-extra-${TAG}.src llvm/tools/clang/tools/extra
# mv compiler-rt-${TAG}.src llvm/projects/compiler-rt

# wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${TAG}/llvm-${TAG}.src.tar.xz
# wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${TAG}/clang-${TAG}.src.tar.xz
# wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${TAG}/clang-tools-extra-${TAG}.src.tar.xz
# wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${TAG}/compiler-rt-${TAG}.src.tar.xz

# svn co http://llvm.org/svn/llvm-project/llvm/tags/${TAG}/final llvm
# cd llvm/tools
# svn co http://llvm.org/svn/llvm-project/cfe/tags/${TAG}/final/ clang
# cd ../..
# cd llvm/tools/clang/tools
# svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/${TAG}/final/ extra
# cd ../../../..
# cd llvm/projects
# svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/${TAG}/final/ compiler-rt
# cd ../..
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUT ../llvm 1> /dev/null
make -j$THREADS 1> /dev/null
make install 1> /dev/null
