#!/usr/bin/env bash
set -ex
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CFG="-O3 -march=native -funroll-loops -ftree-vectorize "

GCCVV="gcc-8.3.0"
LINUX="linux-5.0.2"
GLIBC="glibc-2.29"
BINUT="binutils-2.32"
MPFRR="mpfr-4.0.2"

TARGET=x86_64-linux-gnu
OUT=/opt/chain/${GCCVV}-opt

THREADS="${THREADS:-12}"

rm -rf build glibc $OUT
mkdir -p build glibc tar $OUT
cd tar
set +x

[ ! -f ./${GCCVV}.tar.gz ]  && wget https://ftp.gnu.org/gnu/gcc/${GCCVV}/${GCCVV}.tar.gz
[ ! -f ./${BINUT}.tar.gz ]  && wget http://ftpmirror.gnu.org/binutils/${BINUT}.tar.gz
[ ! -f ./${LINUX}.tar.xz ]  && wget https://www.kernel.org/pub/linux/kernel/v5.x/${LINUX}.tar.xz
[ ! -f ./${GLIBC}.tar.xz ]  && wget http://ftpmirror.gnu.org/glibc/${GLIBC}.tar.xz
[ ! -f ./${MPFRR}.tar.xz ]  && wget http://ftpmirror.gnu.org/mpfr/${MPFRR}.tar.xz
[ ! -f ./gmp-6.1.2.tar.xz ] && wget http://ftpmirror.gnu.org/gmp/gmp-6.1.2.tar.xz
[ ! -f ./mpc-1.1.0.tar.gz ] && wget http://ftpmirror.gnu.org/mpc/mpc-1.1.0.tar.gz

[ ! -d ./${GCCVV} ]     && tar xf ${GCCVV}.tar.gz
[ ! -d ./${BINUT} ] && tar xf ${BINUT}.tar.gz
[ ! -d ./${LINUX} ]  && tar xf ${LINUX}.tar.xz
[ ! -d ./${GLIBC} ]    && tar xf ${GLIBC}.tar.xz
[ ! -d ./${MPFRR} ]    && tar xf ${MPFRR}.tar.xz
[ ! -d ./gmp-6.1.2 ]     && tar xf gmp-6.1.2.tar.xz
[ ! -d ./mpc-1.1.0 ]     && tar xf mpc-1.1.0.tar.gz



set -x
cd ${LINUX}
make SHELL='sh' CFLAGS="${CFG}" INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
cd ..

rm -rf build-binutils
mkdir -p build-binutils
cd build-binutils
../${BINUT}/configure CFLAGS="${CFG}" --prefix=$OUT --target=$TARGET --disable-nls --with-system-zlib  --without-selinux 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" -j$THREADS 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" install 1> /dev/null
cd ..

cd ${GCCVV}
ln -nsf ../${MPFRR} mpfr
ln -nsf ../gmp-6.1.2 gmp
ln -nsf ../mpc-1.1.0 mpc
cd ../..

cd build
../tar/${GCCVV}/configure CFLAGS="${CFG}"  --prefix=$OUT --enable-languages=c,c++ --enable-multilib --without-selinux 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" -j$THREADS all-gcc 1> /dev/null
make SHELL='sh' CFLAGS="${CFG}" install-gcc 1> /dev/null
cd ..

cd glibc
../tar/${GLIBC}/configure CFLAGS="${CFG}" --prefix=$OUT/$TARGET --build=$MACHTYPE --with-headers=$OUT/$TARGET/include --without-selinux libc_cv_forced_unwind=yes --enable-multilib  1> /dev/null
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
