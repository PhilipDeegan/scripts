
set -e
OUT=/opt/chain/clang5
THREADS=4
mkdir -p $OUT
svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_500/final llvm
cd llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_500/final/ clang
cd ../..
cd llvm/tools/clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_500/final/ extra
cd ../../../..
cd llvm/projects
svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_500/final/ compiler-rt
cd ../..
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUT ../llvm 1> /dev/null
make -j$THREADS 1> /dev/null
make install 1> /dev/null
