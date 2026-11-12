#!/usr/bin/env bash
#
# Build a gcc cross toolchain (binutils + gcc + glibc|musl) into its own sysroot.
#
#   ARCH=aarch64 LIBC=glibc ./gcc-cross.sh
#   ARCH=armhf   LIBC=musl  ./gcc-cross.sh
#   ARCH=x86_64  LIBC=musl  ./gcc-cross.sh     # x86_64 musl toolchain
#
# ARCH:  x86_64 | aarch64 | armhf (armv7-a, hard float, thumb2)
# LIBC:  glibc | musl
#
# Result: /opt/chain/gcc-<ver>-<target>/bin/<target>-gcc
#   musl toolchains build static and shared libs; use -static for fully static binaries.
#
# HOSTED=1 (musl only): also build a second toolchain *with* the first one, whose own
#   executables (gcc, cc1, ld, ...) are static musl binaries running on <target>.
#   No host libc dependency: drop it on Alpine, an old distro, a Pi, ... and it runs.
#   Self contained (bundles musl + kernel headers as its sysroot) and relocatable.
#   Result: /opt/chain/gcc-<ver>-<target>-native/bin/gcc
#   Programs it links dynamically need /lib/ld-musl-*.so.1 on the machine; -static doesn't.
#   No linker plugin (a static ld can't dlopen), -flto still works via collect2.
#
# Host needs: gcc g++ make bison flex gawk python3 texinfo xz wget rsync
#
set -euo pipefail
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ARCH="${ARCH:-aarch64}"
LIBC="${LIBC:-glibc}"
THREADS="${THREADS:-$(nproc --all)}"

GCC_V="${GCC_V:-16.2.0}"
BINUTILS_V="${BINUTILS_V:-2.47}"
GLIBC_V="${GLIBC_V:-2.44}"
MUSL_V="${MUSL_V:-1.2.6}"
LINUX_V="${LINUX_V:-6.18.63}"   # LTS, only used for headers

GCC_EXTRA=()
case "$ARCH" in
  x86_64)  KARCH=x86_64; MARCH=x86_64;  T_GNU=x86_64-linux-gnu;       T_MUSL=x86_64-linux-musl ;;
  aarch64) KARCH=arm64;  MARCH=aarch64; T_GNU=aarch64-linux-gnu;      T_MUSL=aarch64-linux-musl ;;
  armhf)   KARCH=arm;    MARCH=arm;     T_GNU=arm-linux-gnueabihf;    T_MUSL=arm-linux-musleabihf
           GCC_EXTRA=(--with-arch=armv7-a --with-fpu=vfpv3-d16 --with-float=hard --with-mode=thumb) ;;
  *) echo "unknown ARCH=$ARCH (x86_64|aarch64|armhf)" >&2; exit 1 ;;
esac
case "$LIBC" in
  glibc) TARGET=$T_GNU ;;
  musl)  TARGET=$T_MUSL; GCC_EXTRA+=(--disable-libsanitizer) ;;
  *) echo "unknown LIBC=$LIBC (glibc|musl)" >&2; exit 1 ;;
esac
HOSTED="${HOSTED:-0}"
if [ "$HOSTED" = 1 ] && [ "$LIBC" != musl ]; then echo "HOSTED=1 needs LIBC=musl" >&2; exit 1; fi

BUILD="$(gcc -dumpmachine)"
OUT="${OUT:-/opt/chain/gcc-${GCC_V}-${TARGET}}"
SYSROOT="$OUT/$TARGET/sysroot"
NATIVE="${NATIVE:-${OUT}-native}"
TAR="${TAR:-$CWD/tar}"
WORK="${WORK:-$CWD/work/$TARGET}"
LOGS="$WORK/logs"
export PATH="$OUT/bin:$PATH"

# quiet runner: full output goes to a log, tail of it is printed on failure
run() {
  local log="$LOGS/$1.log"; shift
  echo ">> $* (log: $log)"
  "$@" >>"$log" 2>&1 || { tail -n 60 "$log"; echo "FAILED: $*" >&2; exit 1; }
}
fetch() { [ -f "$TAR/$(basename "$1")" ] || wget -q -P "$TAR" "$1"; }
unpack() { [ -d "$WORK/src/$1" ] || tar xf "$TAR/$2" -C "$WORK/src"; }

rm -rf "$WORK/build" "$LOGS" "$OUT"
[ "$HOSTED" = 1 ] && rm -rf "$NATIVE"
mkdir -p "$TAR" "$WORK/src" "$WORK/build" "$LOGS" "$OUT"

## sources
fetch "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_V}/gcc-${GCC_V}.tar.xz"
fetch "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_V}.tar.xz"
fetch "https://cdn.kernel.org/pub/linux/kernel/v${LINUX_V%%.*}.x/linux-${LINUX_V}.tar.xz"
unpack "gcc-${GCC_V}"           "gcc-${GCC_V}.tar.xz"
unpack "binutils-${BINUTILS_V}" "binutils-${BINUTILS_V}.tar.xz"
unpack "linux-${LINUX_V}"       "linux-${LINUX_V}.tar.xz"
if [ "$LIBC" = glibc ]; then
  fetch "https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_V}.tar.xz"
  unpack "glibc-${GLIBC_V}" "glibc-${GLIBC_V}.tar.xz"
else
  fetch "https://musl.libc.org/releases/musl-${MUSL_V}.tar.gz"
  unpack "musl-${MUSL_V}" "musl-${MUSL_V}.tar.gz"
fi
# gmp/mpfr/mpc/isl at versions matching this gcc (checksummed)
[ -e "$WORK/src/gcc-${GCC_V}/gmp" ] || (cd "$WORK/src/gcc-${GCC_V}" && run prereqs ./contrib/download_prerequisites)

## sysroot skeleton: keep lib64 -> lib so crt files are found regardless of multilib dir names
mkdir -p "$SYSROOT/usr/lib" "$SYSROOT/lib"
ln -sfn lib "$SYSROOT/lib64"
ln -sfn lib "$SYSROOT/usr/lib64"

## 1. binutils
mkdir -p "$WORK/build/binutils" && cd "$WORK/build/binutils"
run binutils "$WORK/src/binutils-${BINUTILS_V}/configure" --prefix="$OUT" --target="$TARGET" \
  --with-sysroot="$SYSROOT" --disable-nls --disable-werror --disable-multilib --disable-gdb
run binutils make -j"$THREADS"
run binutils make install

## 2. kernel headers
run linux make -C "$WORK/src/linux-${LINUX_V}" ARCH="$KARCH" INSTALL_HDR_PATH="$SYSROOT/usr" headers_install

## 3. musl headers (no compiler needed; lets gcc configure see a libc)
if [ "$LIBC" = musl ]; then
  run musl-hdr make -C "$WORK/src/musl-${MUSL_V}" ARCH="$MARCH" prefix=/usr DESTDIR="$SYSROOT" install-headers
fi

## 4. gcc compiler only
mkdir -p "$WORK/build/gcc" && cd "$WORK/build/gcc"
run gcc "$WORK/src/gcc-${GCC_V}/configure" --prefix="$OUT" --target="$TARGET" --build="$BUILD" \
  --with-sysroot="$SYSROOT" --enable-languages=c,c++ --disable-multilib --disable-nls "${GCC_EXTRA[@]}"
run gcc make -j"$THREADS" all-gcc
run gcc make install-gcc

## 5. libc
if [ "$LIBC" = glibc ]; then
  # 5a. headers + startfiles + dummy libc.so, enough to build libgcc
  mkdir -p "$WORK/build/glibc" && cd "$WORK/build/glibc"
  run glibc "$WORK/src/glibc-${GLIBC_V}/configure" --prefix=/usr --build="$BUILD" --host="$TARGET" \
    --with-headers="$SYSROOT/usr/include" --disable-werror libc_cv_forced_unwind=yes
  run glibc make install-bootstrap-headers=yes install_root="$SYSROOT" install-headers
  run glibc make -j"$THREADS" csu/subdir_lib
  install csu/crt1.o csu/crti.o csu/crtn.o "$SYSROOT/usr/lib"
  "$TARGET-gcc" -nostdlib -nostartfiles -shared -x c /dev/null -o "$SYSROOT/usr/lib/libc.so"
  touch "$SYSROOT/usr/include/gnu/stubs.h"

  cd "$WORK/build/gcc"
  run gcc make -j"$THREADS" all-target-libgcc
  run gcc make install-target-libgcc

  # 5b. full glibc
  cd "$WORK/build/glibc"
  run glibc make -j"$THREADS"
  run glibc make install_root="$SYSROOT" install
else
  # 5a. static libgcc is all musl needs
  cd "$WORK/build/gcc"
  run gcc make -j"$THREADS" enable_shared=no all-target-libgcc
  run gcc make enable_shared=no install-target-libgcc

  # 5b. full musl
  mkdir -p "$WORK/build/musl" && cd "$WORK/build/musl"
  run musl env CC="$TARGET-gcc" CROSS_COMPILE="$TARGET-" "$WORK/src/musl-${MUSL_V}/configure" \
    --prefix=/usr --target="$TARGET" --syslibdir=/lib
  run musl make -j"$THREADS"
  run musl make DESTDIR="$SYSROOT" install
fi

## 6. full gcc; rebuild libgcc against the real libc (stage-1 one used a dummy/static libc)
cd "$WORK/build/gcc"
rm -rf "$TARGET/libgcc"
run gcc make -j"$THREADS"
run gcc make install

## smoke test
cd "$WORK"
printf '#include <iostream>\nint main(){ std::cout << "hi\\n"; }\n' > hello.cpp
"$TARGET-g++" hello.cpp -o hello
"$TARGET-g++" -static hello.cpp -o hello-static
file hello hello-static
echo "done: $OUT/bin/$TARGET-gcc"

[ "$HOSTED" = 1 ] || exit 0

## 7. HOSTED: rebuild binutils + gcc with the cross toolchain, static, host=target
# sysroot is the prefix itself (copy of the cross sysroot), so gcc/ld treat it as relocatable
mkdir -p "$NATIVE"
cp -a "$SYSROOT/." "$NATIVE/"
HOST_TOOLS=(CC="$TARGET-gcc -static --static" CXX="$TARGET-g++ -static --static"
            AR="$TARGET-ar" RANLIB="$TARGET-ranlib")

mkdir -p "$WORK/build/n-binutils" && cd "$WORK/build/n-binutils"
run n-binutils "$WORK/src/binutils-${BINUTILS_V}/configure" "${HOST_TOOLS[@]}" \
  --prefix="$NATIVE" --build="$BUILD" --host="$TARGET" --target="$TARGET" \
  --with-sysroot="$NATIVE" --disable-nls --disable-werror --disable-multilib --disable-gdb \
  --disable-shared --disable-plugins --disable-gprofng
run n-binutils make -j"$THREADS"
run n-binutils make install

mkdir -p "$WORK/build/n-gcc" && cd "$WORK/build/n-gcc"
run n-gcc "$WORK/src/gcc-${GCC_V}/configure" "${HOST_TOOLS[@]}" \
  --prefix="$NATIVE" --build="$BUILD" --host="$TARGET" --target="$TARGET" \
  --with-sysroot="$NATIVE" --with-build-sysroot="$NATIVE" \
  --enable-languages=c,c++ --disable-multilib --disable-nls --disable-plugin "${GCC_EXTRA[@]}"
# configure probes the *cross* ld (plugin capable) and would make -fuse-linker-plugin the
# default, which the static ld above can't honour. Force it off.
run n-gcc make configure-gcc
sed -i 's/^#define HAVE_LTO_PLUGIN .*/#define HAVE_LTO_PLUGIN 0/' gcc/auto-host.h
run n-gcc make -j"$THREADS"
run n-gcc make install

file "$NATIVE/bin/gcc" "$NATIVE/bin/ld" "$NATIVE/libexec/gcc/$TARGET/$GCC_V/cc1plus"
if [ "$(uname -m)" = "$ARCH" ]; then   # can only run it here if it's our arch
  cd "$WORK"
  "$NATIVE/bin/g++" -static hello.cpp -o hello-native && ./hello-native
fi
echo "done: $NATIVE/bin/gcc"
