
# THIS SCRIPT BUILDS GCC AND INSTALLS TO PWD/gcc/bin
# THIS SCRIPT BUILDS GLIBC AND INSTALLS TO PWD/gcc
#
#
DIR=`echo $PWD`
mkdir gcc
OUT=$DIR/gcc
mkdir tar
cd tar
wget https://ftp.gnu.org/gnu/gcc/gcc-5.1.0/gcc-5.1.0.tar.gz
# wget http://ftpmirror.gnu.org/binutils/binutils-2.25.tar.gz
wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.1.1.tar.xz
wget http://ftpmirror.gnu.org/glibc/glibc-2.21.tar.xz
wget http://ftpmirror.gnu.org/mpfr/mpfr-3.1.3.tar.xz
wget http://ftpmirror.gnu.org/gmp/gmp-6.0.0a.tar.xz
wget http://ftpmirror.gnu.org/mpc/mpc-1.0.3.tar.gz
for f in `ls`; do tar xf $f; done
cd linux-4.1.1
make INSTALL_HDR_PATH=$OUT/x86_64-linux-gnu headers_install
cd ..

cd gcc-5.1.0
ln -s ../mpc-1.0.3 mpc
ln -s ../gmp-6.0.0 gmp
ln -s ../mpfr-3.1.3 mpfr
cd ../..

cd build
../tar/gcc-5.1.0/configure --prefix=$OUT --enable-languages=c,c++ --disable-multilib
make -j4 all-gcc
make install-gcc
cd ..

cd glibc
../tar/glibc-2.21/configure --prefix=$OUT/x86_64-linux-gnu --build=$MACHTYPE --with-headers=$OUT/x86_64-linux-gnu/include --disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
mkdir $OUT/x86_64-linux-gnu/lib
install csu/crt1.o csu/crti.o csu/crtn.o $OUT/x86_64-linux-gnu/lib
gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $OUT/x86_64-linux-gnu/lib/libc.so
touch $OUT/x86_64-linux-gnu/include/gnu/stubs.h
cd ..

cd build
make -j4 all-target-libgcc
make install-target-libgcc
cd ..

cd glibc
make -j4
make install
cd ..

cd build
make -j4
make install
cd ..
