
set -ex

TARGET=x86_64-linux-gnu
OUT=/opt/chain/gcc8.2.0
THREADS=6
rm -rf build glibc $OUT
mkdir -p build glibc tar $OUT
cd tar
set +x
[ ! -f ./gcc-8.2.0.tar.gz ]     && wget https://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-8.2.0.tar.gz
[ ! -f ./binutils-2.31.tar.gz ] && wget http://ftpmirror.gnu.org/binutils/binutils-2.31.tar.gz
[ ! -f ./linux-4.15.1.tar.xz ]  && wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.15.1.tar.xz
[ ! -f ./glibc-2.28.tar.xz ]    && wget http://ftpmirror.gnu.org/glibc/glibc-2.28.tar.xz
[ ! -f ./mpfr-4.0.1.tar.xz ]    && wget http://ftpmirror.gnu.org/mpfr/mpfr-4.0.1.tar.xz
[ ! -f ./gmp-6.1.2.tar.xz ]     && wget http://ftpmirror.gnu.org/gmp/gmp-6.1.2.tar.xz
[ ! -f ./mpc-1.1.0.tar.gz ]     && wget http://ftpmirror.gnu.org/mpc/mpc-1.1.0.tar.gz

[ ! -d ./gcc-8.2.0 ]     && tar xf gcc-8.2.0.tar.gz
[ ! -d ./binutils-2.31 ] && tar xf binutils-2.31.tar.gz
[ ! -d ./linux-4.15.1 ]  && tar xf linux-4.15.1.tar.xz
[ ! -d ./glibc-2.28 ]    && tar xf glibc-2.28.tar.xz
[ ! -d ./mpfr-4.0.1 ]    && tar xf mpfr-4.0.1.tar.xz
[ ! -d ./gmp-6.1.2 ]     && tar xf gmp-6.1.2.tar.xz
[ ! -d ./mpc-1.1.0 ]     && tar xf mpc-1.1.0.tar.gz

set -x
cd linux-4.15.1
make INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
cd ..

rm -rf build-binutils
mkdir -p build-binutils
cd build-binutils
../binutils-2.31/configure --prefix=$OUT --target=$TARGET --disable-nls --with-system-zlib  --without-selinux 1> /dev/null
make -j$THREADS 1> /dev/null
make install 1> /dev/null
cd ..

cd gcc-8.2.0
ln -nsf ../mpfr-4.0.1 mpfr
ln -nsf ../gmp-6.1.2 gmp
ln -nsf ../mpc-1.1.0 mpc
cd ../..

cd build
../tar/gcc-8.2.0/configure --prefix=$OUT --enable-languages=c,c++ --enable-multilib --without-selinux 1> /dev/null
make -j$THREADS all-gcc 1> /dev/null
make install-gcc 1> /dev/null
cd ..

cd glibc
../tar/glibc-2.28/configure --prefix=$OUT/$TARGET --build=$MACHTYPE --with-headers=$OUT/$TARGET/include --without-selinux libc_cv_forced_unwind=yes --enable-multilib  1> /dev/null
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
