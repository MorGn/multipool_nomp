#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

# set our variables
source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/nomp/.nomp.conf
source $HOME/multipool/daemon_builder/.first_build.cnf
cd $HOME/multipool/daemon_builder

echo -e " Starting initial coin build, this may take awhile...$COL_RESET"

# Select random unused port for coin.conf creation
function EPHYMERAL_PORT(){
    LPORT=32768;
    UPORT=60999;
    while true; do
        MPORT=$[$LPORT + ($RANDOM % $UPORT)];
        (echo "" >/dev/tcp/127.0.0.1/${MPORT}) >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo $MPORT;
            return 0;
        fi
    done
}

# Set what we need
now=$(date +"%m_%d_%Y")
set -e
NPROC=$(nproc)
if [[ ! -e '$STORAGE_ROOT/coin_builder/temp_coin_builds' ]]; then
sudo mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds
else
  echo -e "$GREEN temp_coin_builds already exists.... Skipping$COL_RESET"
fi

# Just double checking folder permissions
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/daemon_builder/temp_coin_builds

cd $STORAGE_ROOT/daemon_builder/temp_coin_builds

coin_dir=$coin_name$now

# save last coin information in case coin build fails
echo '
lastcoin='"${coin_dir}"'
' | sudo -E tee $STORAGE_ROOT/daemon_builder/temp_coin_builds/.lastcoin.conf >/dev/null 2>&1

# Clone the coin
if [[ ! -e $coin_dir ]]; then
  git clone $coin_repo $coin_dir
else
  echo "$STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir already exists.... Skipping"
  echo "If there was an error in the build use the build error options on the installer"
  exit 0
fi

cd "${coin_dir}"

# Build the coin under the proper configuration
if [[ ("$autogen" == "true") ]]; then
  if [[ ("$berkeley" == "4.8") ]]; then
    echo -e " Building using Berkeley 4.8...$COL_RESET"
    basedir=$(pwd)
    sh autogen.sh >/dev/null 2>&1
    sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/share/genbuild.sh
    sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/leveldb/build_detect_platform
    ./configure CPPFLAGS="-I$STORAGE_ROOT/berkeley/db4/include -O2" LDFLAGS="-L$STORAGE_ROOT/berkeley/db4/lib" --without-gui --disable-tests >/dev/null 2>&1
  else
    echo -e " Building using Berkeley 5.1...$COL_RESET"
    basedir=$(pwd)
    sh autogen.sh >/dev/null 2>&1
    sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/share/genbuild.sh
    sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/leveldb/build_detect_platform
    ./configure CPPFLAGS="-I$STORAGE_ROOT/berkeley/db5/include -O2" LDFLAGS="-L$STORAGE_ROOT/berkeley/db5/lib" --without-gui --disable-tests >/dev/null 2>&1
  fi
  make -j$(nproc)
  else
    echo -e " Building using makefile.unix method...$COL_RESET"
    cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src
  if [[ ! -e '$STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/obj' ]]; then
    mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/obj
  else
    echo -e " Hey the developer did his job and the src/obj dir is there!$COL_RESET"
  fi
  if [[ ! -e '$STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/obj/zerocoin' ]]; then
    mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/obj/zerocoin
  else
  echo -e " Wow even the /src/obj/zerocoin is there! Good job developer!$COL_RESET"
  fi
  cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/leveldb
  sudo chmod +x build_detect_platform
  sudo make clean >/dev/null 2>&1
  sudo make libleveldb.a libmemenv.a >/dev/null 2>&1
  cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src
  sed -i '/USE_UPNP:=0/i BDB_LIB_PATH = /home/crypto-data/berkeley/db4/lib\nBDB_INCLUDE_PATH = /home/crypto-data/berkeley/db4/include\nOPENSSL_LIB_PATH = /home/crypto-data/openssl/lib\nOPENSSL_INCLUDE_PATH = /home/crypto-data/openssl/include' makefile.unix
  make -j$NPROC -f makefile.unix USE_UPNP=-
fi

clear

# LS the SRC dir to have user input bitcoind and bitcoin-cli names
cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/
find . -maxdepth 1 -type f \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"

read -e -p "Please enter the coind name from the directory above, example bitcoind :" coind
read -e -p "Is there a coin-cli, example bitcoin-cli [y/N] :" ifcoincli

if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
  read -e -p "Please enter the coin-cli name :" coincli
fi

clear

# Strip and copy to /usr/bin
sudo strip $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/$coind
sudo cp $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/$coind /usr/bin

if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
  sudo strip $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/$coincli
  sudo cp $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir/src/$coincli /usr/bin
fi

# Make the new wallet folder and autogenerate the coin.conf
if [[ ! -e '$STORAGE_ROOT/wallets' ]]; then
  sudo mkdir -p $STORAGE_ROOT/wallets
fi

sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/wallets
mkdir -p $STORAGE_ROOT/wallets/."${coind::-1}"

rpc_password=$(openssl rand -base64 29 | tr -d "=+/")
rpc_port=$(EPHYMERAL_PORT)

echo 'rpcuser=NOMPrpc
rpcpassword='${rpc_password}'
rpcport='${rpc_port}'
rpcthreads=8
rpcallowip=127.0.0.1
# onlynet=ipv4
maxconnections=12
daemon=1
gen=0
' | sudo -E tee $STORAGE_ROOT/wallets/."${coind::-1}"/"${coind::-1}".conf >/dev/null 2>&1

echo -e "Starting ${coind::-1}"
/usr/bin/"${coind}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}.conf" -daemon -shrinkdebugfile

# Create easy daemon start file
coin_symbol_lower=${coin_symbol,,}
echo ''${coind}' -datadir=${STORAGE_ROOT}/wallets/.'${coind::-1}' -conf='${coind::-1}'.conf -daemon -shrinkdebugfile
' | sudo -E tee /usr/bin/"${coin_symbol_lower}_start" >/dev/null 2>&1
sudo chmod +x /usr/bin/"${coin_symbol_lower}_start"

# If we made it this far everything built fine removing last coin.conf and build directory
sudo rm -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/.lastcoin.conf
sudo rm -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/$coin_dir
sudo rm -r $HOME/multipool/daemon_builder/.first_build.cnf

echo 'rpcpassword='${rpcpassword}'
rpcport='${rpcport}''| sudo -E tee $HOME/multipool/daemon_builder/.first_build.cnf >/dev/null 2>&1
sudo chmod 0600 $HOME/multipool/daemon_builder/.first_build.cnf
echo -e "$GREEN Initial coin build completed...$COL_RESET"

cd $HOME/multipool/nomp
