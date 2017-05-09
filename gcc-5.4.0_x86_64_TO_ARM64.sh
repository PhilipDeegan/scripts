set -e
set -x
# THIS SCRIPT BUILDS GCC AND INSTALLS TO PWD/gcc/bin
# THIS SCRIPT BUILDS GLIBC AND INSTALLS TO PWD/gcc
#
#

TARGET=aarch64-linux
OUT=/opt/chain/gcc5.4.0_aarch64
THREADS=20
rm -rf build glibc $OUT
mkdir -p build glibc tar $OUT
cd tar
set +x
[ ! -f ./gcc-5.4.0.tar.gz ]     && wget https://ftp.gnu.org/gnu/gcc/gcc-5.4.0/gcc-5.4.0.tar.gz
[ ! -f ./binutils-2.25.tar.gz ] && wget http://ftpmirror.gnu.org/binutils/binutils-2.25.tar.gz
[ ! -f ./linux-4.7.5.tar.xz ]   && wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.7.5.tar.xz
[ ! -f ./glibc-2.24.tar.xz ]    && wget http://ftpmirror.gnu.org/glibc/glibc-2.24.tar.xz
[ ! -f ./mpfr-3.1.4.tar.xz ]    && wget http://ftpmirror.gnu.org/mpfr/mpfr-3.1.4.tar.xz
[ ! -f ./gmp-6.1.0.tar.xz ]     && wget http://ftpmirror.gnu.org/gmp/gmp-6.1.0.tar.xz
[ ! -f ./mpc-1.0.3.tar.gz ]     && wget http://ftpmirror.gnu.org/mpc/mpc-1.0.3.tar.gz

[ ! -d ./gcc-5.4.0 ]        && tar xf gcc-5.4.0.tar.gz
[ ! -d ./binutils-2.25 ]    && tar xf binutils-2.25.tar.gz
[ ! -d ./linux-4.7.5 ]      && tar xf linux-4.7.5.tar.xz
[ ! -d ./glibc-2.24 ]       && tar xf glibc-2.24.tar.xz
[ ! -d ./mpfr-3.1.4 ]       && tar xf mpfr-3.1.4.tar.xz
[ ! -d ./gmp-6.1.0 ]        && tar xf gmp-6.1.0.tar.xz
[ ! -d ./mpc-1.0.3 ]        && tar xf mpc-1.0.3.tar.gz

set -x
cd linux-4.7.5
make ARCH=arm64 INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
cd ..

rm -rf build-binutils
mkdir -p build-binutils
cd build-binutils
../binutils-2.25/configure --prefix=$OUT --target=$TARGET --disable-nls 1> /dev/null
make -j$THREADS 1> /dev/null
make install 1> /dev/null
cd ..

cd gcc-5.4.0
ln -nsf ../mpfr-3.1.4 mpfr
ln -nsf ../gmp-6.1.0 gmp
ln -nsf ../mpc-1.0.3 mpc
cd ../..

cd build
PATH=$OUT/bin:$PATH ../tar/gcc-5.4.0/configure --prefix=$OUT --enable-languages=c,c++ --disable-multilib --disable-nls 1> /dev/null
PATH=$OUT/bin:$PATH make -j$THREADS all-gcc 1> /dev/null
PATH=$OUT/bin:$PATH make install-gcc 1> /dev/null
cd ..

cd glibc
../tar/glibc-2.24/configure --prefix=$OUT/$TARGET --build=$MACHTYPE --with-headers=$OUT/$TARGET/include  libc_cv_forced_unwind=yes --disable-multilib 1> /dev/null
PATH=$OUT/bin:$PATH make install-bootstrap-headers=yes install-headers 1> /dev/null
PATH=$OUT/bin:$PATH make -j$THREADS csu/subdir_lib 1> /dev/null
mkdir -p $OUT/$TARGET/lib 1> /dev/null
PATH=$OUT/bin:$PATH install csu/crt1.o csu/crti.o csu/crtn.o $OUT/$TARGET/lib 1> /dev/null
PATH=$OUT/bin:$PATH $TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $OUT/$TARGET/lib/libc.so 1> /dev/null
touch $OUT/$TARGET/include/gnu/stubs.h 1> /dev/null
cd ..

cd build
PATH=$OUT/bin:$PATH make -j$THREADS all-target-libgcc 1> /dev/null
PATH=$OUT/bin:$PATH make install-target-libgcc 1> /dev/null
cd ..

cd glibc
PATH=$OUT/bin:$PATH make -j$THREADS 1> /dev/null
PATH=$OUT/bin:$PATH make install 1> /dev/null
cd ..

cd build
PATH=$OUT/bin:$PATH make -j$THREADS 1> /dev/null
PATH=$OUT/bin:$PATH make install 1> /dev/null
cd ..
