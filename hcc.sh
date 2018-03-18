#! /bin/bash

## Prerequisites
##      cmake 3.7+
##
## some requirements - debian stretch expected
##   apt-get install libc++-dev libc++1 libelf1 libelf-dev git pkg-config
##   apt-get install libdw1 texinfo autoconf wget g++-multilib libunwind-dev
##   apt-get install make python2.7 fakeroot libc++abi-dev libpci-dev
#

THREADS=7
BUILD="$HOME/tmp/rocm"
INSTALL="/opt/rocm"
GITHUB="https://github.com/RadeonOpenCompute"
set -ex

export LLVM_BUILD=$INSTALL/clang4

mkdir -p $BUILD && cd $BUILD
[ ! -d llvm_amd-common ] && git clone --depth 1 $GITHUB/llvm llvm_amd-common
cd llvm_amd-common/tools/

[ ! -d lld   ] && git clone --depth 1 $GITHUB/lld lld
[ ! -d clang ] && git clone --depth 1 $GITHUB/clang clang

rm -rf ../build && mkdir -p ../build && cd ../build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL/clang4 -DLLVM_TARGET_TO_BUILD="AMDGPU;X86" ..
make -j$THREADS
make install

cd $BUILD
[ ! -d thunk ] && git clone --depth 1 https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface thunk
cd thunk && mkdir -p build && cd build && \
  cmake -DCMAKE_MODULE_PATH=${PWD}/../cmake_modules -DCMAKE_INSTALL_PREFIX=$INSTALL ..
make clean && make -j$THREADS && make install
cd ..
cp -r include $INSTALL/libhsakmt
cp build/lnx64a/lib* $INSTALL/libhsakmt/lib
mkdir -p $INSTALL/lib && cd $INSTALL/lib
for f in $(find $INSTALL/libhsakmt/lib -name "libhsa*.so*"); do ln -fs $f; done

cd $BUILD
[ ! -d runtime ] && git clone --depth 1 $GITHUB/ROCR-Runtime runtime -b roc-1.7.x
rm -rf runtime/build && mkdir -p runtime/build && cd runtime/build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL \
                -DHSAKMT_INC=$INSTALL/libhsakmt/include \
                -DHSAKMT_LIB=$INSTALL/libhsakmt/lib \
                -DHSAKMT_INC_PATH=$INSTALL/libhsakmt/include \
                -DHSAKMT_LIB_PATH=$INSTALL/libhsakmt/lib ../src
make -j$THREADS && make install
mkdir -p $INSTALL/lib && cd $INSTALL/lib
for f in $(find $BUILD/runtime/build -name "libhsa*.so*"); do ln -fs $f; done

cd $BUILD
[ ! -d devlibs ] && git clone --depth 1 $GITHUB/ROCm-Device-Libs devlibs
rm -rf devlibs/build && mkdir -p devlibs/build && 
cd devlibs/build
CC=$LLVM_BUILD/bin/clang cmake -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$INSTALL/dlibs -DLLVM_DIR=$LLVM_BUILD ..
CC=$LLVM_BUILD/bin/clang make -j$THREADS
CC=$LLVM_BUILD/bin/clang make install

cd $BUILD
[ ! -d hcc ] && git clone --depth 1 --recursive -b clang_tot_upgrade https://github.com/RadeonOpenCompute/hcc
rm -rf hcc/build && mkdir -p hcc/build && cd hcc/build
CXX=$LLVM_BUILD/bin/clang++ CC=$LLVM_BUILD/bin/clang cmake -DCMAKE_BUILD_TYPE=Release \
               -DROCM_DEVICE_LIB_DIR=$INSTALL/dlibs/lib -DCMAKE_INSTALL_PREFIX=$INSTALL/hcc \
               -DHSA_HEADER_DIR=$INSTALL/include -DHSA_LIBRARY_DIR=$INSTALL/lib ..
CXX=$LLVM_BUILD/bin/clang++ CC=$LLVM_BUILD/bin/clang make -j$THREADS world
CXX=$LLVM_BUILD/bin/clang++ CC=$LLVM_BUILD/bin/clang make -j$THREADS
CXX=$LLVM_BUILD/bin/clang++ CC=$LLVM_BUILD/bin/clang make install
cd $INSTALL/lib
for f in $(find $INSTALL/hcc/lib -name "lib*.so*"); do ln -fs $f; done

ln -s $INSTALL/hcc/bin $INSTALL/bin
ln -s $INSTALL/hcc/include/ $INSTALL/hcc/include/hcc

export PATH=$INSTALL/hcc/bin:$PATH
mkdir -p $BUILD/test
cd $BUILD/test
wget https://gist.githubusercontent.com/scchan/540d410456e3e2682dbf018d3c179008/raw/f12152f8a79a577b1afb4454b849dae0f76a124d/saxpy.cpp
hcc $(hcc-config --cxxflags --ldflags) saxpy.cpp -o saxpy
LD_LIBRARY_PATH=$INSTALL/lib ./saxpy
