set -e
set -x
# BIN UTILS REQUIRES texinfo

# THIS SCRIPT BUILDS GCC CROSS FOR ARM AND INSTALLS TO PWD/gcc/bin
# THIS SCRIPT BUILDS GLIBC AND INSTALLS TO PWD/gcc
#
#

TARGET=arm-linux-gnueabihf
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUT=$CWD/gcc_5.3_ARMv7-A
rm -rf build glibc $OUT
mkdir -p build glibc tar $OUT
cd tar
set +x
if [ ! -f ./gcc-5.3.0.tar.bz2 ]; then wget https://ftp.gnu.org/gnu/gcc/gcc-5.3.0/gcc-5.3.0.tar.bz2; fi
if [ ! -f ./binutils-2.25.tar.gz ]; then wget http://ftpmirror.gnu.org/binutils/binutils-2.25.tar.gz; fi
if [ ! -f ./linux-4.2.3.tar.xz ]; then wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.2.3.tar.xz; fi
if [ ! -f ./glibc-2.22.tar.xz ]; then wget http://ftpmirror.gnu.org/glibc/glibc-2.22.tar.xz; fi
if [ ! -f ./mpfr-3.1.3.tar.xz ]; then wget http://ftpmirror.gnu.org/mpfr/mpfr-3.1.3.tar.xz; fi
if [ ! -f ./gmp-6.0.0a.tar.xz ]; then wget http://ftpmirror.gnu.org/gmp/gmp-6.0.0a.tar.xz; fi
if [ ! -f ./mpc-1.0.3.tar.gz ]; then wget http://ftpmirror.gnu.org/mpc/mpc-1.0.3.tar.gz; fi

if [ ! -d ./gcc-5.3.0 ]; then tar xf gcc-5.3.0.tar.bz2; fi
if [ ! -d ./binutils-2.25 ]; then tar xf binutils-2.25.tar.gz; fi
if [ ! -d ./linux-4.2.3 ]; then tar xf linux-4.2.3.tar.xz; fi
if [ ! -d ./glibc-2.22 ]; then tar xf glibc-2.22.tar.xz; fi
if [ ! -d ./mpfr-3.1.3 ]; then tar xf mpfr-3.1.3.tar.xz; fi
if [ ! -d ./gmp-6.0.0 ]; then tar xf gmp-6.0.0a.tar.xz; fi
if [ ! -d ./mpc-1.0.3 ]; then tar xf mpc-1.0.3.tar.gz; fi

set -x
cd linux-4.2.3
make ARCH=arm INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
cd ..

rm -rf build-binutils
mkdir -p build-binutils
cd build-binutils
../binutils-2.25/configure --prefix=$OUT --target=$TARGET --disable-nls --with-arch=armv7-a 1> /dev/null
make -j6 1> /dev/null
make install 1> /dev/null
cd ..

cd gcc-5.3.0
ln -nsf ../mpc-1.0.3 mpc
ln -nsf ../gmp-6.0.0 gmp
ln -nsf ../mpfr-3.1.3 mpfr
cd ../..

cd build
PATH=$OUT/bin:$PATH ../tar/gcc-5.3.0/configure --prefix=$OUT --enable-languages=c,c++ --target=$TARGET --disable-nls --with-arch=armv7-a 1> /dev/null
PATH=$OUT/bin:$PATH make -j6 all-gcc 1> /dev/null
PATH=$OUT/bin:$PATH make install-gcc 1> /dev/null
cd ..

cd glibc
PATH=$OUT/bin:$PATH ../tar/glibc-2.22/configure --prefix=$OUT/$TARGET --build=$MACHTYPE --host=$TARGET --with-headers=$OUT/$TARGET/include libc_cv_forced_unwind=yes --with-arch=armv7-a 1> /dev/null
PATH=$OUT/bin:$PATH make install-bootstrap-headers=yes install-headers 1> /dev/null
PATH=$OUT/bin:$PATH make -j6 csu/subdir_lib 1> /dev/null
mkdir -p  $OUT/$TARGET/lib
PATH=$OUT/bin:$PATH install csu/crt1.o csu/crti.o csu/crtn.o $OUT/$TARGET/lib 1> /dev/null
PATH=$OUT/bin:$PATH $TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $OUT/$TARGET/lib/libc.so 1> /dev/null
touch $OUT/$TARGET/include/gnu/stubs.h 1> /dev/null
cd ..

cd build
PATH=$OUT/bin:$PATH make -j6 all-target-libgcc 1> /dev/null
PATH=$OUT/bin:$PATH make install-target-libgcc 1> /dev/null
cd ..

cd glibc
PATH=$OUT/bin:$PATH make -j6 1> /dev/null
PATH=$OUT/bin:$PATH make install 1> /dev/null
cd ..

cd build
PATH=$OUT/bin:$PATH make -j6 1> /dev/null
PATH=$OUT/bin:$PATH make install 1> /dev/null
cd ..
