#!/usr/bin/env bash
set -ex
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CFG="-O3 -march=native -funroll-loops -ftree-vectorize -fPIC"

# configured for JUNO FC34?
GCCVV="gcc-11.beta"
LINUX="linux-5.11.11"
GLIBC="glibc-2.33"
# BINUT="binutils-2.31.1"
BINUT="binutils-$(ldd --version | head -n 1 | cut -d' ' -f4)"
MPFRR="mpfr-4.1.0"
GMP="gmp-6.2.0"
MPC="mpc-1.2.0"
NVPTX_TOOLS="nvptx-tools" # https://github.com/MentorEmbedded/nvptx-tools
NVPTX_NEWLIB="nvptx-newlib" # https://github.com/MentorEmbedded/nvptx-newlib
GCC_GIT_MIRROR="gcc-mirror"

TARGET=x86_64-linux-gnu
OUT=${HOME}/acc/${GCCVV}
THREADS="${THREADS:10}"
echo $THREADS

rm -rf build glibc $OUT
mkdir -p build glibc tar $OUT
cd tar
set +x

[ ! -f ./${GCCVV}.tar.gz ]  && curl -Lo ${GCCVV}.tar.gz https://api.github.com/repos/gcc-mirror/gcc/tarball/releases/gcc-11
[ ! -f ./${BINUT}.tar.gz ]  && wget http://ftpmirror.gnu.org/binutils/${BINUT}.tar.gz
[ ! -f ./${LINUX}.tar.xz ]  && wget https://www.kernel.org/pub/linux/kernel/v5.x/${LINUX}.tar.xz
[ ! -f ./${GLIBC}.tar.xz ]  && wget http://ftpmirror.gnu.org/glibc/${GLIBC}.tar.xz
[ ! -f ./${MPFRR}.tar.xz ]  && wget http://ftpmirror.gnu.org/mpfr/${MPFRR}.tar.xz
[ ! -f ./${GMP}.tar.xz ] && wget http://ftpmirror.gnu.org/gmp/${GMP}.tar.xz
[ ! -f ./${MPC}.tar.gz ] && wget http://ftpmirror.gnu.org/mpc/${MPC}.tar.gz

[ ! -d ./${NVPTX_TOOLS} ]   && git clone https://github.com/MentorEmbedded/${NVPTX_TOOLS}  -b master --depth 1
[ ! -d ./${NVPTX_NEWLIB} ]  && git clone https://github.com/MentorEmbedded/${NVPTX_NEWLIB} -b master --depth 1

[ ! -d ./${GCCVV} ]  && tar xf ${GCCVV}.tar.gz
[ ! -d ./${BINUT} ]  && tar xf ${BINUT}.tar.gz
[ ! -d ./${LINUX} ]  && tar xf ${LINUX}.tar.xz
[ ! -d ./${GLIBC} ]  && tar xf ${GLIBC}.tar.xz
[ ! -d ./${MPFRR} ]  && tar xf ${MPFRR}.tar.xz
[ ! -d ./${GMP} ] && tar xf ${GMP}.tar.xz
[ ! -d ./${MPC} ] && tar xf ${MPC}.tar.gz

set -x

find . -depth -type d -name "${GCC_GIT_MIRROR}-*" -execdir mv {} ${GCCVV} \;

cd ${NVPTX_TOOLS}
./configure --prefix=$OUT/offloading
make SHELL='sh' CFLAGS="${CFG}"
make SHELL='sh' CFLAGS="${CFG}" install
cd ..


cd ${LINUX}
make SHELL='sh' CFLAGS="${CFG}" INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
cd ..

rm -rf build-binutils
mkdir -p build-binutils
cd build-binutils
../${BINUT}/configure CFLAGS="${CFG}" --prefix=$OUT --target=$TARGET --disable-nls --with-system-zlib --without-selinux 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" -j$THREADS 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" install 1> /dev/null
cd ..

cd ${GCCVV}
ln -nsf ../${MPFRR} mpfr
ln -nsf ../${GMP} gmp
ln -nsf ../${MPC} mpc
ln -nsf ../${NVPTX_NEWLIB} newlib
cd ../..

cd build
# https://gist.github.com/matthiasdiener/e318e7ed8815872e9d29feb3b9c8413f
../tar/${GCCVV}/configure CFLAGS="${CFG}" --prefix=$OUT --enable-languages=c,c++,lto --without-selinux --disable-multilib \
                                          --target=nvptx-none --enable-as-accelerator-for=x86_64-pc-linux-gnu \
                                          --with-build-time-tools=$OUT/offloading/nvptx-none/bin --disable-sjlj-exceptions \
                                          --enable-newlib-io-long-long
                                          #--enable-offload-targetsamdgcn-amdhsa=/install/usr/local/amdgcn-amdhsa 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" -j$THREADS all-gcc 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" install-gcc 1> /dev/null
cd ..

cd glibc
../tar/${GLIBC}/configure CFLAGS="${CFG}" --prefix=$OUT/$TARGET --build=$MACHTYPE --with-headers=$OUT/$TARGET/include --without-selinux libc_cv_forced_unwind=yes --disable-multilib  1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" install-bootstrap-headers=yes install-headers 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" -j$THREADS csu/subdir_lib 1> /dev/null
mkdir -p $OUT/$TARGET/lib 1> /dev/null
install csu/crt1.o csu/crti.o csu/crtn.o $OUT/$TARGET/lib 1> /dev/null
gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $OUT/$TARGET/lib/libc.so 1> /dev/null
touch $OUT/$TARGET/include/gnu/stubs.h 1> /dev/null
cd ..

cd build
make SHELL='sh' CFLAGS="${CFG}" -j$THREADS all-target-libgcc 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" install-target-libgcc 1> /dev/null
cd ..

cd glibc
make SHELL='sh' CFLAGS="${CFG}" -j$THREADS 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" install 1> /dev/null
cd ..

cd build
make SHELL='sh' CFLAGS="${CFG}" -j$THREADS 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" install 1> /dev/null
cd ..
