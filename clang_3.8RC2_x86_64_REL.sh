
OUT=/home/philix/clang
mkdir -p $OUT
svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_380/rc2 llvm
cd llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_380/rc2/ clang
cd ../..
cd llvm/tools/clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_380/rc2/ extra
cd ../../../..
cd llvm/projects
svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_380/rc2/ compiler-rt
cd ../..
mkdir build
cd build
../llvm/configure --prefix=$OUT --enable-optimized1> /dev/null
make -j 4 1> /dev/null
make install 1> /dev/null
