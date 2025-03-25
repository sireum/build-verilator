set -ex
export COSMOCC_V=`cat cosmocc.ver`
export VERILATOR_V=`cat verilator.ver`
export ARCH=`arch`
if [[ -d /proc/sys/fs/binfmt_misc/register ]]; then
  sudo wget -O /usr/bin/ape https://cosmo.zip/pub/cosmos/bin/ape-$(uname -m).elf
  sudo chmod +x /usr/bin/ape
  sudo sh -c "echo ':APE:M::MZqFpD::/usr/bin/ape:' >/proc/sys/fs/binfmt_misc/register" || true
  sudo sh -c "echo ':APE-jart:M::jartsr::/usr/bin/ape:' >/proc/sys/fs/binfmt_misc/register" || true
fi
rm -fR cosmocc verilator cosmocc-*.zip
wget https://github.com/jart/cosmopolitan/releases/download/$COSMOCC_V/cosmocc-$COSMOCC_V.zip
mkdir cosmocc
cd cosmocc
unzip -qq ../cosmocc-$COSMOCC_V.zip
cd bin
ln -s cosmocc cc
ln -s cosmoc++ c++
ln -s cosmoc++ g++
cd ../include
ln -s /usr/include/FlexLexer.h .
cd ../..
export PATH=`pwd`/cosmocc/bin:$PATH
export CXX=`pwd`/cosmocc/bin/$ARCH-unknown-cosmo-c++
export CC=`pwd`/cosmocc/bin/$ARCH-unknown-cosmo-cc
export AR=`pwd`/cosmocc/bin/$ARCH-unknown-cosmo-ar
git clone --recursive --depth=1 --branch v$VERILATOR_V https://github.com/verilator/verilator.git verilator.git
cd verilator.git
git grep -lz "llround(scale)" | xargs -0 sed -i'' -e 's/llround(scale)/static_cast<long long>(scale < 0.0? floor(scale - 0.5) : floor(scale + 0.5))/g'
autoconf
./configure
make -j4
cd bin
ls -lah
ldd verilator_bin || true
ldd verilator_bin_dbg || true
git grep -lz '"verilator_bin"' | xargs -0 sed -i'' -e 's/"verilator_bin"/"verilator_bin.com"/g'
cp verilator_bin verilator ../..
