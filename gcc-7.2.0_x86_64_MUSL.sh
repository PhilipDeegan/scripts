
set -ex

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ARCH="x86_64"
TARGET='amd64-linux-musl'
PREFIX=/opt/chain/gcc7.2.0_MUSL
THREADS=8
export PATH="$PREFIX/bin:$PATH"

rm -rf build musl $PREFIX
mkdir -p build musl tar $PREFIX
cd tar
set +x
[ ! -f ./gcc-7.2.0.tar.gz ]     && wget https://ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz
[ ! -f ./binutils-2.29.tar.gz ] && wget http://ftpmirror.gnu.org/binutils/binutils-2.29.tar.gz
[ ! -f ./linux-4.11.12.tar.xz ] && wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.11.12.tar.xz
[ ! -f ./musl-1.1.19.tar.gz ]   && wget http://git.musl-libc.org/cgit/musl/snapshot/musl-1.1.19.tar.gz
[ ! -f ./mpfr-3.1.5.tar.xz ]    && wget http://ftpmirror.gnu.org/mpfr/mpfr-3.1.5.tar.xz
[ ! -f ./gmp-6.1.2.tar.xz ]     && wget http://ftpmirror.gnu.org/gmp/gmp-6.1.2.tar.xz
[ ! -f ./mpc-1.0.3.tar.gz ]     && wget http://ftpmirror.gnu.org/mpc/mpc-1.0.3.tar.gz

[ ! -d ./gcc-7.2.0 ]     && tar xf gcc-7.2.0.tar.gz
[ ! -d ./binutils-2.29 ] && tar xf binutils-2.29.tar.gz
[ ! -d ./linux-4.11.12 ] && tar xf linux-4.11.12.tar.xz
[ ! -d ./musl-1.1.19 ]   && tar xf musl-1.1.19.tar.gz
[ ! -d ./mpfr-3.1.5 ]    && tar xf mpfr-3.1.5.tar.xz
[ ! -d ./gmp-6.1.2 ]     && tar xf gmp-6.1.2.tar.xz
[ ! -d ./mpc-1.0.3 ]     && tar xf mpc-1.0.3.tar.gz

## Abort on error
set -e

## Clean if exists
rm -rf "$PREFIX"
mkdir -p "$PREFIX"

echo Working...

## Fix path to usr inside $PREFIX
cd "$PREFIX"
ln -nfs . usr
cd $CWD

## Build temp musl
rm -rf build-musl
mkdir build-musl
cd build-musl
CROSS_COMPILE=" " ../tar/musl*/configure --prefix="$PREFIX" --target="$ARCH" --disable-shared  1>/dev/null
make -j$THREADS 1>/dev/null
make install 1>/dev/null
cd ..
rm -rf build-musl
echo "1/7 musl done."

## Build temp binutils
rm -rf build-binutils
mkdir build-binutils
cd build-binutils
../tar/binutils-2.29/configure --prefix="$PREFIX" --target="$TARGET" --disable-bootstrap --disable-werror 1>/dev/null
make -j$THREADS 1>/dev/null
make install 1>/dev/null
cd ..
rm -rf build-binutils
echo "2/7 BINUTILS done."

## Build temp gcc
rm -rf build-gcc
mkdir build-gcc
cd build-gcc
../tar/gcc-7.2.0/configure --prefix="$PREFIX" --target="$TARGET" --with-sysroot="$PREFIX" --disable-bootstrap --disable-werror --disable-shared  --disable-multilib --disable-libsanitizer --enable-languages=c,c++ 1>/dev/null
make -j$THREADS 1>/dev/null
make install 1>/dev/null
cd ..
rm -rf build-gcc
echo "3/7 GCC done."

## Fix paths
export CC="$TARGET-gcc"
export CXX="$TARGET-g++"

export PREFIX="`pwd`/$TARGET"
export CFLAGS="$CFLAGS -static --sysroot="$PREFIX""
export CXXFLAGS="$CXXFLAGS -static --sysroot="$PREFIX""

## Clean existing
rm -rf "$PREFIX"

## Create linux headers
cd $CWD/tar/linux-4.11.12
make ARCH="$ARCH" INSTALL_HDR_PATH="$PREFIX" headers_install 1>/dev/null
make clean 1>/dev/null

echo "4/7 LINUX headers done."

## Fix usr path
cd "$PREFIX"
ln -nfs . usr
cd $CWD

## Build final musl
rm -rf build-musl
mkdir build-musl
cd build-musl
CROSS_COMPILE="$TARGET-" ../tar/musl*/configure --prefix="$PREFIX" --target="$ARCH" --disable-shared  --syslibdir="$PREFIX/lib"  1>/dev/null
make -j$THREADS 1>/dev/null
make install 1>/dev/null
cd ..
rm -rf build-musl
echo "5/7 musl done."

## Build final binutils
rm -rf build-binutils
mkdir build-binutils
cd build-binutils
../tar/binutils-2.29/configure --prefix="$PREFIX" --target="$TARGET" --disable-bootstrap --disable-werror 1>/dev/null
make tooldir="$PREFIX" -j$THREADS 1>/dev/null
make tooldir="$PREFIX" install 1>/dev/null
cd ..
rm -rf build-binutils
echo "6/7 BINUTILS done."

## Build final gcc
rm -rf build-gcc
mkdir build-gcc
cd build-gcc
../tar/gcc-7.2.0/configure --prefix="$PREFIX" --target="$TARGET" --with-sysroot="$PREFIX" --disable-multilib --disable-bootstrap --disable-werror --disable-shared --enable-languages=c,c++ --disable-libsanitizer --libexecdir="$PREFIX/lib" 1>/dev/null
make -j$THREADS 1>/dev/null
make install 1>/dev/null
cd ..
rm -rf build-gcc

## Move gcc include/lib to correct directories
cd "$PREFIX/$TARGET"
cp -rf include ..
cp -rf lib ..
cp -rf lib64/. ../lib
rm -rf "$PREFIX/$TARGET"

echo "7/7 GCC done."

# rm -rf "$PREFIX/../build-$TARGET"