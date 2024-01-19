#!/usr/bin/env bash
set -ex
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CFG="-O3 -march=native -funroll-loops -ftree-vectorize -fPIC"

# configured for JUNO FC34?
GCCVV="gcc-10.3.0"
LINUX="linux-5.11.11"
BINUT="binutils-2.32"
GLIBC="glibc-2.33"
MPFRR="mpfr-4.1.0"
GMP="gmp-6.2.0"
MPC="mpc-1.2.0"
NVPTX_TOOLS="nvptx-tools" # https://github.com/MentorEmbedded/nvptx-tools
NVPTX_NEWLIB="nvptx-newlib" # https://github.com/MentorEmbedded/nvptx-newlib
GCC_GIT_MIRROR="gcc-mirror"

TARGET=x86_64-redhat-linux
OUT=${HOME}/acc/${GCCVV}_host
THREADS="${THREADS:-10}"
echo $THREADS

# rm -rf build glibc $OUT
# mkdir -p build glibc tar $OUT

cd tar
set +x

[ ! -f ./${BINUT}.tar.gz ]  && wget http://ftpmirror.gnu.org/binutils/${BINUT}.tar.gz
[ ! -f ./${LINUX}.tar.xz ]  && wget https://www.kernel.org/pub/linux/kernel/v5.x/${LINUX}.tar.xz
[ ! -f ./${GCCVV}.tar.gz ]  && wget https://ftp.gnu.org/gnu/gcc/${GCCVV}/${GCCVV}.tar.gz
[ ! -f ./${MPFRR}.tar.xz ]  && wget http://ftpmirror.gnu.org/mpfr/${MPFRR}.tar.xz
[ ! -f ./${GMP}.tar.xz ] && wget http://ftpmirror.gnu.org/gmp/${GMP}.tar.xz
[ ! -f ./${MPC}.tar.gz ] && wget http://ftpmirror.gnu.org/mpc/${MPC}.tar.gz

[ ! -d ./${NVPTX_TOOLS} ]   && git clone https://github.com/MentorEmbedded/${NVPTX_TOOLS}  -b master --depth 1
[ ! -d ./${NVPTX_NEWLIB} ]  && git clone https://github.com/MentorEmbedded/${NVPTX_NEWLIB} -b master --depth 1

[ ! -d ./${BINUT} ]  && tar xf ${BINUT}.tar.gz
[ ! -d ./${LINUX} ]  && tar xf ${LINUX}.tar.xz
[ ! -d ./${GCCVV} ]  && tar xf ${GCCVV}.tar.gz
[ ! -d ./${MPFRR} ]  && tar xf ${MPFRR}.tar.xz
[ ! -d ./${GMP} ] && tar xf ${GMP}.tar.xz
[ ! -d ./${MPC} ] && tar xf ${MPC}.tar.gz

set -x

# cd ${LINUX}
# make SHELL='sh' CFLAGS="${CFG}" INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
# cd ..

# rm -rf build-binutils
# mkdir -p build-binutils
# cd build-binutils
# ../${BINUT}/configure CFLAGS="${CFG}" --prefix=$OUT --target=$TARGET --disable-nls --with-system-zlib --without-selinux 1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" -j$THREADS 1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" install 1> /dev/null
# cd ..

# cd ${GCCVV}
# ln -nsf ../${MPFRR} mpfr
# ln -nsf ../${GMP} gmp
# ln -nsf ../${MPC} mpc
# rm -f newlib
# cd ../..

# cd build
# ../tar/${GCCVV}/configure CFLAGS="${CFG}"  --prefix=$OUT --enable-languages=c,c++ --disable-multilib --without-selinux 1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" -j$THREADS all-gcc 1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" install-gcc 1> /dev/null
# cd ..

# cd glibc
# ../tar/${GLIBC}/configure CFLAGS="${CFG}" --prefix=$OUT/$TARGET --build=$MACHTYPE --with-headers=$OUT/$TARGET/include --without-selinux libc_cv_forced_unwind=yes --disable-multilib  1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" install-bootstrap-headers=yes install-headers 1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" -j$THREADS csu/subdir_lib 1> /dev/null
# mkdir -p $OUT/$TARGET/lib 1> /dev/null
# install csu/crt1.o csu/crti.o csu/crtn.o $OUT/$TARGET/lib 1> /dev/null
# gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $OUT/$TARGET/lib/libc.so 1> /dev/null
# touch $OUT/$TARGET/include/gnu/stubs.h 1> /dev/null
# cd ..

# cd build
# make SHELL='sh' CFLAGS="${CFG}" -j$THREADS all-target-libgcc 1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" install-target-libgcc 1> /dev/null
# cd ..

# cd glibc
# make SHELL='sh' CFLAGS="${CFG}" -j$THREADS 1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" install 1> /dev/null
# cd ..

# cd build
# make SHELL='sh' CFLAGS="${CFG}" -j$THREADS 1> /dev/null
# make SHELL='sh' CFLAGS="${CFG}" install 1> /dev/null
# cd ..

####

cd $CWD

HOST_OUT=${OUT}
OUT=${HOME}/acc/${GCCVV}
rm -rf build glibc $OUT

# FUNKY!
DUBLYOU_L="-Wl,-rpath,${HOST_OUT}/lib64:${HOST_OUT}/${TARGET}/lib -Wl,--dynamic-linker=${HOST_OUT}/${TARGET}/lib/ld-linux-x86-64.so.2"

PATH=$HOST_OUT/bin:$PATH gcc -v

cd tar/${NVPTX_TOOLS}
PATH=$HOST_OUT/bin:$PATH ./configure --prefix=$OUT  \
  CC="gcc -m64 ${DUBLYOU_L}" \
  CXX="g++ -m64 ${DUBLYOU_L}" LDFLAGS="${DUBLYOU_L}"
PATH=$HOST_OUT/bin:$PATH make SHELL='sh' CFLAGS="${CFG}"
PATH=$HOST_OUT/bin:$PATH make SHELL='sh' CFLAGS="${CFG}" install
cd ..

cd ${GCCVV}
ln -nsf ../${NVPTX_NEWLIB} newlib
cd ../..

# https://gist.github.com/matthiasdiener/e318e7ed8815872e9d29feb3b9c8413f
rm -rf build && mkdir build && cd build
PATH=$HOST_OUT/bin:$PATH ../tar/${GCCVV}/configure CFLAGS="${CFG}" \
  --disable-multilib \
  --target=nvptx-none \
  --with-build-time-tools=$OUT/nvptx-none/bin \
  --enable-as-accelerator-for=$target \
  --disable-sjlj-exceptions \
  --enable-newlib-io-long-long \
  --enable-languages="c,c++,fortran,lto" \
  --prefix=$OUT \
  CC="gcc -m64 ${DUBLYOU_L}" \
  CXX="g++ -m64 ${DUBLYOU_L}" LDFLAGS="${DUBLYOU_L}"
PATH=$HOST_OUT/bin:$PATH make -j$THREADS
PATH=$HOST_OUT/bin:$PATH make install
cd ..

cuda=/usr/local/cuda
rm -rf build && mkdir build && cd build
PATH=$HOST_OUT/bin:$PATH ../tar/${GCCVV}/configure CFLAGS="${CFG}" \
  --disable-multilib \
  --enable-offload-targets=nvptx-none \
  --with-cuda-driver-include=$cuda/include \
  --with-cuda-driver-lib=$cuda/lib64 \
  --disable-bootstrap \
  --disable-multilib \
  --enable-languages="c,c++,fortran,lto" \
  --prefix=$OUT \
  CC="gcc -m64 ${DUBLYOU_L}" \
  CXX="g++ -m64 ${DUBLYOU_L}" LDFLAGS="${DUBLYOU_L}"
PATH=$HOST_OUT/bin:$PATH make -j$THREADS
PATH=$HOST_OUT/bin:$PATH make install
cd ..


cd ${GCCVV}
rm newlib
cd ../..
