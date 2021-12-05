#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/nomp/.nomp.conf

echo -e " Building web file structure and copying files...$COL_RESET"
cd $STORAGE_ROOT/nomp/nomp_setup/nomp

sudo cp -r $STORAGE_ROOT/nomp/nomp_setup/nomp/configuration/. $STORAGE_ROOT/nomp/configuration
sudo cp -r $STORAGE_ROOT/nomp/nomp_setup/nomp/core/. $STORAGE_ROOT/nomp/core
sudo cp -r $STORAGE_ROOT/nomp/nomp_setup/nomp/site/web/. $STORAGE_ROOT/nomp/site/web/

echo -e " Generating nginx configs...$COL_RESET"
if [[ ("$Using_Sub_Domain" == "y" || "$Using_Sub_Domain" == "Y" || "$Using_Sub_Domain" == "yes" || "$Using_Sub_Domain" == "Yes" || "$Using_Sub_Domain" == "YES") ]]; then
  cd $HOME/multipool/nomp
  source nginx_subdomain_nonssl.sh
    if [[ ("$Install_SSL" == "y" || "$Install_SSL" == "Y" || "$Install_SSL" == "yes" || "$Install_SSL" == "Yes" || "$Install_SSL" == "YES") ]]; then
      cd $HOME/multipool/nomp
      source nginx_subdomain_ssl.sh
    fi
      else
        cd $HOME/multipool/nomp
        source nginx_domain_nonssl.sh
    if [[ ("$Install_SSL" == "y" || "$Install_SSL" == "Y" || "$Install_SSL" == "yes" || "$Install_SSL" == "Yes" || "$Install_SSL" == "YES") ]]; then
      cd $HOME/multipool/nomp
      source nginx_domain_ssl.sh
    fi
fi
echo -e "$GREEN Done...$COL_RESET"

echo -e " Setting correct folder permissions...$COL_RESET"
whoami=`whoami`
sudo usermod -aG www-data $whoami
sudo usermod -a -G www-data $whoami
sudo usermod -a -G crypto-data $whoami
sudo usermod -a -G crypto-data www-data
sudo find $STORAGE_ROOT/nomp/ -type d -exec chmod 775 {} +
sudo find $STORAGE_ROOT/nomp/ -type f -exec chmod 664 {} +
sudo chgrp www-data $STORAGE_ROOT -R
sudo chmod g+w $STORAGE_ROOT -R
echo -e "$GREEN Done...$COL_RESET"
echo -e "$GREEN Web build complete...$COL_RESET"

cd $HOME/multipool/nomp
