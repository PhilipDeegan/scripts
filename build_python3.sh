exit 1 # this file isn't valid, more to read/copy

THREADS=8

# debian: apt-get install -y git build-essential libbz2-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev tk-dev liblzma-dev
# rhel  : dnf install -y git openssl-devel bzip2-devel libffi-devel xz-devel sqlite-devel readline-devel

BASE_DIR=/opt/py/python-3.11.4_sqlite

./configure CFLAGS="-g3 -O3 -march=native -fPIC -I/usr/include/openssl" \
  CXXFLAGS="-g3 -O3 -march=native -fPIC -I/usr/include/openssl" \
  --enable-shared LDFLAGS="-L/usr/lib -L/usr/lib/x86_64-linux-gnu -Wl,-rpath=${BASE_DIR}/lib:/usr/lib/x86_64-linux-gnu" \
  --prefix=${BASE_DIR} \
  --enable-optimizations --with-ensurepip=install 

make PROFILE_TASK="-m test.regrtest --pgo -j$THREADS" -j$THREADS
make PROFILE_TASK="-m test.regrtest --pgo -j$THREADS" -j$THREADS install
