
# BIN UTILS REQUIRES texinfo

# THIS SCRIPT BUILDS GCC CROSS FOR ARM AND INSTALLS TO PWD/gcc/bin
# THIS SCRIPT BUILDS GLIBC AND INSTALLS TO PWD/gcc
#
#
DIR=`echo $PWD`
mkdir gcc build glibc
OUT=$DIR/gcc
cd tar
wget https://ftp.gnu.org/gnu/gcc/gcc-5.1.0/gcc-5.1.0.tar.gz
wget http://ftpmirror.gnu.org/binutils/binutils-2.25.tar.gz
wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.1.1.tar.xz
wget http://ftpmirror.gnu.org/glibc/glibc-2.21.tar.xz
wget http://ftpmirror.gnu.org/mpfr/mpfr-3.1.3.tar.xz
wget http://ftpmirror.gnu.org/gmp/gmp-6.0.0a.tar.xz
wget http://ftpmirror.gnu.org/mpc/mpc-1.0.3.tar.gz
for f in `ls`; do tar xf $f; done

cd linux-4.1.1
make ARCH=arm INSTALL_HDR_PATH=$OUT/arm-linux-gnueabi headers_install
cd ..

mkdir build-binutils
cd build-binutils
../binutils-2.25/configure --prefix=$OUT --target=arm-linux-gnueabi
make -j6
make install
cd ..

cd gcc-5.1.0
ln -s ../mpc-1.0.3 mpc
ln -s ../gmp-6.0.0 gmp
ln -s ../mpfr-3.1.3 mpfr
cd ../..

cd build
PATH=$OUT/bin:$PATH ../tar/gcc-5.1.0/configure --prefix=$OUT --enable-languages=c,c++ --target=arm-linux-gnueabi
PATH=$OUT/bin:$PATH make -j6 all-gcc
PATH=$OUT/bin:$PATH make install-gcc
cd ..

cd glibc
PATH=$OUT/bin:$PATH ../tar/glibc-2.21/configure --prefix=$OUT/arm-linux-gnueabi --build=$MACHTYPE --host=arm-linux-gnueabi --target=arm-linux-gnueabi --with-headers=$OUT/arm-linux-gnueabi/include libc_cv_forced_unwind=yes
PATH=$OUT/bin:$PATH make install-bootstrap-headers=yes install-headers
PATH=$OUT/bin:$PATH make -j6 csu/subdir_lib
mkdir $OUT/arm-linux-gnueabi/lib
PATH=$OUT/bin:$PATH install csu/crt1.o csu/crti.o csu/crtn.o $OUT/arm-linux-gnueabi/lib
PATH=$OUT/bin:$PATH arm-linux-gnueabi-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $OUT/arm-linux-gnueabi/lib/libc.so
touch $OUT/arm-linux-gnueabi/include/gnu/stubs.h
cd ..

cd build
PATH=$OUT/bin:$PATH make -j6 all-target-libgcc
PATH=$OUT/bin:$PATH make install-target-libgcc
cd ..

cd glibc
PATH=$OUT/bin:$PATH make -j6
PATH=$OUT/bin:$PATH make install
cd ..

cd build
PATH=$OUT/bin:$PATH make -j6
PATH=$OUT/bin:$PATH make install 			# if problems with "rcp/xdr.h" see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=64839
cd ..
