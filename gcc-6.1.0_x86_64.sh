set -e
set -x
# THIS SCRIPT BUILDS GCC AND INSTALLS TO PWD/gcc/bin
# THIS SCRIPT BUILDS GLIBC AND INSTALLS TO PWD/gcc
#
#

TARGET=x86_64-linux-gnu
OUT=/home/philix/app/gcc6.1.0
THREADS=4
mkdir -p build glibc tar $OUT
cd tar
set +x
if [ ! -f ./gcc-6.1.0.tar.gz ]; then wget https://ftp.gnu.org/gnu/gcc/gcc-6.1.0/gcc-6.1.0.tar.gz; fi
# if [ ! -f ./binutils-2.26.tar.gz ]; then wget http://ftpmirror.gnu.org/binutils/binutils-2.26.tar.gz; fi
if [ ! -f ./linux-4.5.2.tar.xz ]; then wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.5.2.tar.xz; fi
if [ ! -f ./glibc-2.23.tar.xz ]; then wget http://ftpmirror.gnu.org/glibc/glibc-2.23.tar.xz; fi
if [ ! -f ./mpfr-3.1.4.tar.xz ]; then wget http://ftpmirror.gnu.org/mpfr/mpfr-3.1.4.tar.xz; fi
if [ ! -f ./gmp-6.1.0.tar.xz ]; then wget http://ftpmirror.gnu.org/gmp/gmp-6.1.0.tar.xz; fi
if [ ! -f ./mpc-1.0.3.tar.gz ]; then wget http://ftpmirror.gnu.org/mpc/mpc-1.0.3.tar.gz; fi

if [ ! -d ./gcc-6.1.0 ]; then tar xf gcc-6.1.0.tar.gz; fi
# if [ ! -d ./binutils-2.26 ]; then tar xf binutils-2.26.tar.gz; fi
if [ ! -d ./linux-4.5.2 ]; then tar xf linux-4.5.2.tar.xz; fi
if [ ! -d ./glibc-2.23 ]; then tar xf glibc-2.23.tar.xz; fi
if [ ! -d ./mpfr-3.1.4 ]; then tar xf mpfr-3.1.4.tar.xz; fi
if [ ! -d ./gmp-6.1.0 ]; then tar xf gmp-6.1.0.tar.xz; fi
if [ ! -d ./mpc-1.0.3 ]; then tar xf mpc-1.0.3.tar.gz; fi

set -x
cd linux-4.5.2
make INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
cd ..

cd gcc-6.1.0
ln -nsf ../mpfr-3.1.4 mpfr
ln -nsf ../gmp-6.1.0 gmp
ln -nsf ../mpc-1.0.3 mpc
cd ../..

cd build
../tar/gcc-6.1.0/configure --prefix=$OUT --enable-languages=c,c++  1> /dev/null
make -j$THREADS all-gcc 1> /dev/null
make install-gcc 1> /dev/null
cd ..

cd glibc
../tar/glibc-2.23/configure --prefix=$OUT/$TARGET --build=$MACHTYPE --with-headers=$OUT/$TARGET/include  libc_cv_forced_unwind=yes 1> /dev/null
make install-bootstrap-headers=yes install-headers 1> /dev/null
make -j$THREADS csu/subdir_lib 1> /dev/null
mkdir -p $OUT/$TARGET/lib 1> /dev/null
install csu/crt1.o csu/crti.o csu/crtn.o $OUT/$TARGET/lib 1> /dev/null
gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $OUT/$TARGET/lib/libc.so 1> /dev/null
touch $OUT/$TARGET/include/gnu/stubs.h 1> /dev/null
cd ..

cd build
make -j$THREADS all-target-libgcc 1> /dev/null
make install-target-libgcc 1> /dev/null
cd ..

cd glibc
make -j$THREADS 1> /dev/null
make install 1> /dev/null
cd ..

cd build
make -j$THREADS 1> /dev/null
make install 1> /dev/null
cd ..
