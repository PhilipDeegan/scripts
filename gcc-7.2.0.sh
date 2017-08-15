
set -ex

TARGET=x86_64-linux-gnu
OUT=/opt/chain/gcc7.2.0
THREADS=$(nproc --all)
rm -rf build glibc $OUT
mkdir -p build glibc tar $OUT
cd tar
set +x
[ ! -f ./gcc-7.2.0.tar.gz ]     && wget https://ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz
[ ! -f ./binutils-2.29.tar.gz ] && wget http://ftpmirror.gnu.org/binutils/binutils-2.29.tar.gz
[ ! -f ./linux-4.11.12.tar.xz ] && wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.11.12.tar.xz
[ ! -f ./glibc-2.26.tar.xz ]    && wget http://ftpmirror.gnu.org/glibc/glibc-2.26.tar.xz
[ ! -f ./mpfr-3.1.5.tar.xz ]    && wget http://ftpmirror.gnu.org/mpfr/mpfr-3.1.5.tar.xz
[ ! -f ./gmp-6.1.2.tar.xz ]     && wget http://ftpmirror.gnu.org/gmp/gmp-6.1.2.tar.xz
[ ! -f ./mpc-1.0.3.tar.gz ]     && wget http://ftpmirror.gnu.org/mpc/mpc-1.0.3.tar.gz

[ ! -d ./gcc-7.2.0 ]     && tar xf gcc-7.2.0.tar.gz
[ ! -d ./binutils-2.29 ] && tar xf binutils-2.29.tar.gz
[ ! -d ./linux-4.11.12 ] && tar xf linux-4.11.12.tar.xz
[ ! -d ./glibc-2.26 ]    && tar xf glibc-2.26.tar.xz
[ ! -d ./mpfr-3.1.5 ]    && tar xf mpfr-3.1.5.tar.xz
[ ! -d ./gmp-6.1.2 ]     && tar xf gmp-6.1.2.tar.xz
[ ! -d ./mpc-1.0.3 ]     && tar xf mpc-1.0.3.tar.gz

set -x
cd linux-4.11.12
make INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
cd ..

rm -rf build-binutils
mkdir -p build-binutils
cd build-binutils
../binutils-2.29/configure --prefix=$OUT --target=$TARGET --disable-nls --with-system-zlib 1> /dev/null
make -j$THREADS 1> /dev/null
make install 1> /dev/null
cd ..

cd gcc-7.2.0
ln -nsf ../mpfr-3.1.5 mpfr
ln -nsf ../gmp-6.1.2 gmp
ln -nsf ../mpc-1.0.3 mpc
cd ../..

cd build
../tar/gcc-7.2.0/configure --prefix=$OUT --enable-languages=c,c++ --enable-multilib 1> /dev/null
make -j$THREADS all-gcc 1> /dev/null
make install-gcc 1> /dev/null
cd ..

cd glibc
../tar/glibc-2.26/configure --prefix=$OUT/$TARGET --build=$MACHTYPE --with-headers=$OUT/$TARGET/include  libc_cv_forced_unwind=yes --enable-multilib  1> /dev/null
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
