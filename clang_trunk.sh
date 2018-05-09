
set -e
OUT=/opt/chain/clang
THREADS=8
mkdir -p $OUT
svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm
cd llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/trunk/ clang
cd ../..
cd llvm/tools/clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/trunk/ extra
cd ../../../..
cd llvm/projects
svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk/ compiler-rt
cd ../..
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUT ../llvm 1> /dev/null
make -j$THREADS 1> /dev/null
make install 1> /dev/null
