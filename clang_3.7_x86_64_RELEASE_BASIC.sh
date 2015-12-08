
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mkdir -p $CWD
svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_371/rc1 llvm
cd llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_371/rc1/ clang
cd ../..
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_371/rc1/ extra
cd ../../../..
cd llvm/projects
svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_371/rc1/ compiler-rt
cd ../..
mkdir build
cd build
../llvm/configure --prefix=$CWD --enable-optimized1> /dev/null
make -j 4 1> /dev/null
make install 1> /dev/null
