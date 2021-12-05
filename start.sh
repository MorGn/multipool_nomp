#!/usr/bin/env bash
#####################################################
# This is the entry point for configuring the system.
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
# Ensure Python reads/writes files in UTF-8. If the machine
# triggers some other locale in Python, like ASCII encoding,
# Python may not be able to read/write files. This is also
# in the management daemon startup script and the cron script.

if ! locale -a | grep en_US.utf8 > /dev/null; then
# Generate locale if not exists
hide_output locale-gen en_US.UTF-8
fi

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

# Fix so line drawing characters are shown correctly in Putty on Windows. See #744.
export NCURSES_NO_UTF8_ACS=1

# Create the temporary installation directory if it doesn't already exist.
echo Creating the NOMP directories...
if [ ! -d $STORAGE_ROOT/nomp/nomp_setup ]; then
  sudo mkdir -p $STORAGE_ROOT/{wallets,nomp/{nomp_setup/{tmp,log},configuration/{aux_configs,coins,pool_configs},core,site,logs,starts}}
  sudo touch $STORAGE_ROOT/nomp/nomp_setup/log/installer.log
  sudo mkdir -p $HOME/multipool/daemon_builder
fi

# Set user permission now so we can copy without issues.
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/site
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/logs
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/starts
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/core
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/configuration
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/configuration/aux_configs
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/configuration/coins
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/configuration/pool_configs
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/wallets
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/nomp/nomp_setup/tmp

# Start the installation.
source questions.sh
source system.sh
source self_ssl.sh
source db.sh
source nginx_upgrade.sh
source web.sh
source daemon.sh
source build_coin.sh
source nomp.sh
source motd.sh
if [[ ("$Using_Domain" == "Yes") ]]; then
  source send_mail.sh
fi
source server_harden.sh
source server_cleanup.sh

clear
echo -e "Installation of your NOMP server is now completed."
echo -e "You $RED*MUST REBOOT*$COL_RESET the machine to finalize the machine updates and folder permissions! $MAGENTA NOMP will not function until a reboot is performed!$COL_RESET"
echo
echo -e "$YELLOW If you are using the servers IP instead of a domain name you will be alerted that your website has an invalid certificate.$COL_RESET"
echo
echo -e "$RED By default all stratum ports are blocked by the firewall.$COL_RESET To allow a port through, from the command prompt type $GREEN sudo ufw allow port number.$COL_RESET"
# Done.
echo
echo "-----------------------------------------------"
echo
echo Thank you for using the Ultimate Crypto-Server Setup Installer!
echo
echo To run this installer anytime simply type, multipool!
echo Donations for continued support of this script are welcomed at:
echo
echo BTC 16x9dQBFmpGRBd9dLLLCyKYh5Fqu63WwMx
echo BCH qqmu7zxsg8v725eyk0f4yhz2unvh57kjfulhj8c7h6
echo ETH 0xD4217C4700d5dD2f8Cd1820655308B727De60965
echo LTC LhQmNUoagWbAsvh9xVBFsm2UQoqeGH3vDe

exit 0
