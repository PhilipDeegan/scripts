
TAG="RELEASE_600"

set -e
OUT=/opt/chain/clang6
THREADS=12
mkdir -p $OUT
svn co http://llvm.org/svn/llvm-project/llvm/tags/${TAG}/final llvm
cd llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/tags/${TAG}/final/ clang
cd ../..
cd llvm/tools/clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/${TAG}/final/ extra
cd ../../../..
cd llvm/projects
svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/${TAG}/final/ compiler-rt
cd ../..
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUT ../llvm 1> /dev/null
make -j$THREADS 1> /dev/null
make install 1> /dev/null
