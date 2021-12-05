#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/nomp/.nomp.conf

# Create function for random unused port
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

echo -e " Making the NOMPness Monster...$COL_RESET"
echo -e " Script will seem to hang for several minutes...$COL_RESET"
cd $STORAGE_ROOT/nomp/core/

# NPM install and update, user can ignore errors
npm install bignum >/dev/null 2>&1
echo -e " Still working on it...$COL_RESET"
npm update >/dev/null 2>&1
echo -e " Almost done...$COL_RESET"
npm i npm@latest -g >/dev/null 2>&1
echo -e " Almost there...$COL_RESET"
npm install -g pm2@latest >/dev/null 2>&1
echo -e " Are we there yet...$COL_RESET"
npm install -g npm@latest >/dev/null 2>&1
echo -e " We have successfully hacked the NSA using this server...$COL_RESET"
echo -e "$GREEN Just kidding, we hacked the White House...$COL_RESET"

# SED the config file
sudo sed -i 's/domain_name/'$Domain_Name'/g' $STORAGE_ROOT/nomp/configuration/config.json
sudo sed -i 's/Stratum_URL/'$Stratum_URL'/g' $STORAGE_ROOT/nomp/configuration/config.json
sudo sed -i 's/PASSWORD/'$Admin_Pass'/g' $STORAGE_ROOT/nomp/configuration/config.json
sudo sed -i 's/coin_name/'$coin_name'/g' $STORAGE_ROOT/nomp/configuration/config.json

# Change to the coins config folder check for existing config, if not let the user know.
if [ -f $STORAGE_ROOT/nomp/configuration/coins/${coin_name}.json ]; then
  echo -e " ${coin_name}.json created, release the hounds!"
elif
  [ -f $STORAGE_ROOT/nomp/configuration/coins/${coin_no_coin}.json ]; then
    coin_name=$coin_no_coin
  echo -e " ${coin_name}.json created, release the hounds!"
else
  sudo cp -r $STORAGE_ROOT/nomp/configuration/coins/default.json $STORAGE_ROOT/nomp/configuration/coins/$coin_name.json
  sudo sed -i 's/coin_name/'$coin_name'/g' $STORAGE_ROOT/nomp/configuration/coins/$coin_name.json
  sudo sed -i 's/coin_symbol/'$coin_symbol'/g' $STORAGE_ROOT/nomp/configuration/coins/$coin_name.json
  echo -e "$RED You will need to edit $STORAGE_ROOT/nomp/configuration/coins/${coin_name}.json with additional information.$COL_RESET"
  echo -e "$RED Until you edit this file your pool will not work correctly! Sorry not sorry...$COL_RESET"
fi

# Create coin pool_config json file.
sudo cp -r $STORAGE_ROOT/nomp/configuration/pool_configs/pool_config_base $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json

# Generate our random ports
rand_port_low=$(EPHYMERAL_PORT)
rand_port_var=$(EPHYMERAL_PORT)
rand_port_high=$(EPHYMERAL_PORT)

# Generate new wallet address
if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
wallet="$("${coind::-1}-cli" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}.conf" getnewaddress)"
else
wallet="$("${coind}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}.conf" getnewaddress)"
fi

# SED the pool_config with our variables.
sudo sed -i 's/coin_name/'$coin_name'/g' $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json
sudo sed -i 's/wallet/'$wallet'/g' $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json
sudo sed -i 's/daemon_port/'$rpc_port'/g' $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json
sudo sed -i 's/rpc_user/NOMPrpc/g' $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json
sudo sed -i 's/rpc_pass/'$rpc_password'/g' $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json
sudo sed -i 's/rand_port_low/'$rand_port_low'/g' $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json
sudo sed -i 's/rand_port_var/'$rand_port_var'/g' $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json
sudo sed -i 's/rand_port_high/'$rand_port_high'/g' $STORAGE_ROOT/nomp/configuration/pool_configs/$coin_name.json

 # SED the website files with our variables.
sudo sed -i 's/sed_domain/'$Domain_Name'/g' $STORAGE_ROOT/nomp/site/web/index.html
sudo sed -i 's/sed_domain/'$Domain_Name'/g' $STORAGE_ROOT/nomp/site/web/pages/home.html
sudo sed -i 's/sed_stratum/'$Domain_Name'/g' $STORAGE_ROOT/nomp/site/web/pages/statistics.html

echo -e "$GREEN Done with the NOMP...$COL_RESET"
cd $HOME/multipool/nomp
