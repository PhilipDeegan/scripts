
OUT=/opt/chain/clang
rm -rf $OUT
mkdir -p $OUT
svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_371/rc1 llvm
cd llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_371/rc1/ clang
cd ../..
cd llvm/tools/clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_371/rc1/ extra
cd ../../../..
cd llvm/projects
svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_371/rc1/ compiler-rt
cd ../..
mkdir -p build
cd build
../llvm/configure --prefix=$OUT --enable-optimized 1> /dev/null
make -j 2 1> /dev/null
make install 1> /dev/null
