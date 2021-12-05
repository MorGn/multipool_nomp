#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf

message_box "Ultimate Crypto-Server NOMP Installer" \
"You have choosen to install NOMP Single Server!
\n\nThis will install NOMP and help setup your first coin for the server.
\n\n
\n\nAfter answering the following questions, setup will be mostly automated, until the coin build.
\n\nNOTE: If installing on a system with less then 2 GB of RAM you may experience system issues!"


# Begin user inputted responses for auto install

dialog --title "Using Domain Name" \
--yesno "Are you using a domain name? Example: example.com?
Make sure the DNS is updated!" 7 60
response=$?
case $response in
   0) Using_Domain=yes;;
   1) Using_Domain=no;;
   255) echo "[ESC] key pressed.";;
esac

if [[ ("$Using_Domain" == "yes") ]]; then

dialog --title "Using Sub-Domain" \
--yesno "Are you using a sub-domain for the main website domain? Example pool.example.com?
Make sure the DNS is updated!" 7 60
response=$?
case $response in
   0) Using_Sub_Domain=yes;;
   1) Using_Sub_Domain=no;;
   255) echo "[ESC] key pressed.";;
esac

if [ -z "${Domain_Name:-}" ]; then
DEFAULT_Domain_Name=example.com
input_box "Domain Name" \
"Enter your domain name. If using a subdomain enter the full domain as in pool.example.com
\n\nDo not add www. to the domain name.
\n\nMake sure the domain is pointed to this server before continuing!
\n\nDomain Name:" \
${DEFAULT_Domain_Name} \
DomainName

if [ -z "${Domain_Name}" ]; then
# user hit ESC/cancel
exit
fi
fi

if [ -z "${Stratum_URL:-}" ]; then
DEFAULT_Stratum_URL=stratum.${Domain_Name}
input_box "Stratum URL" \
"Enter your stratum URL. It is recommended to use another subdomain such as stratum.${Domain_Name}
\n\nDo not add www. to the domain name.
\n\nStratum URL:" \
${DEFAULT_Stratum_URL} \
StratumURL

if [ -z "${Stratum_URL}" ]; then
# user hit ESC/cancel
exit
fi
fi

dialog --title "Install SSL" \
--yesno "Would you like the system to install SSL automatically?" 7 60
response=$?
case $response in
   0) Install_SSL=yes;;
   1) Install_SSL=no;;
   255) echo "[ESC] key pressed.";;
esac
else

# If user is not using a domain and is just using the server IP these fileds can be automatically detected.

# Sets server IP automatically
Domain_Name=$(get_publicip_from_web_service 4 || get_default_privateip 4)
Stratum_URL=$(get_publicip_from_web_service 4 || get_default_privateip 4)
Using_Sub_Domain=no
Install_SSL=no
fi

if [ -z "${Admin_Pass:-}" ]; then
DEFAULT_Admin_Pass=$(openssl rand -base64 8 | tr -d "=+/")
input_box "Admin Password" \
"Enter your new Admin password or use this randomly system generated one.
\n\nUnfortunatley dialog doesnt let you copy. So you have to write it down.
\n\nAdmin password:" \
$DEFAULT_Admin_Pass \
Admin_Pass

if [ -z "$Admin_Pass" ]; then
# user hit ESC/cancel
exit
fi
fi

if [ -z "${Support_Email:-}" ]; then
DEFAULT_Support_Email=root@localhost
input_box "System Email" \
"Enter an email address for the system to send alerts and other important messages.
\n\nSystem Email:" \
$DEFAULT_Support_Email \
Support_Email

if [ -z "$Support_Email" ]; then
# user hit ESC/cancel
exit
fi
fi

# Get the coind info they want to build during install.

if [ -z "${coin_name:-}" ]; then
DEFAULT_coin_name=Bitcoin
input_box "Coin Name" \
"Enter your coins proper name here. Do not use spaces.
\n\nFor example; Ravencoin, Verge, Bitcoincash, etc...
\n\nCoin Name:" \
$DEFAULT_coin_name \
coin_name

if [ -z "$coin_name" ]; then
# user hit ESC/cancel
exit
fi
fi

if [ -z "${coin_symbol:-}" ]; then
DEFAULT_coin_symbol=BTC
input_box "Coin Symbol" \
"Enter your coins symbol..Make sure to use all CAPS...
\n\nCoin Symbol:" \
$DEFAULT_coin_symbol \
coin_symbol

if [ -z "$coin_symbol" ]; then
# user hit ESC/cancel
exit
fi
fi

if [ -z "${coin_repo:-}" ]; then
DEFAULT_coin_repo="https://github.com/bitcoin/bitcoin.git"
input_box "Default Coin Repo" \
"Enter your coins repo to use..
\n\nIf you are using a private repo and do not specify the user name and password here, you will be promted
\n\nfor it during the installation. Instalaltion will not continue until you enter that information.
\n\nWhen pasting your link CTRL+V does NOT work, you must either SHIFT+RightMouseClick or SHIFT+INSERT!!
\n\nDefault Coin Repo:" \
$DEFAULT_coin_repo \
coin_repo

if [ -z "$coin_repo" ]; then
# user hit ESC/cancel
exit
fi
fi

RESULT=$(dialog --stdout --title "Select the correct build option below" --menu "Choose one" -1 60 4 \
1 "Build coin with Berkeley 4.x" \
2 "Build coin with Berkeley 5.x" \
3 "Build coin with makefile.unix" \
4 Exit)
if [ $RESULT = ]
then
exit ;
fi

if [ $RESULT = 1 ]
then
clear;
echo '
autogen=true
berkeley="4.8"
' | sudo -E tee $HOME/multipool/daemon_builder/.first_build.cnf >/dev/null 2>&1;
fi

if [ $RESULT = 2 ]
then
clear;
echo '
autogen=true
berkeley="5.3"
' | sudo -E tee $HOME/multipool/daemon_builder/.first_build.cnf >/dev/null 2>&1;
fi

if [ $RESULT = 3 ]
then
clear;
echo '
autogen=false
' | sudo -E tee $HOME/multipool/daemon_builder/.first_build.cnf >/dev/null 2>&1;
fi

if [ $RESULT = 4 ]
then
clear;
exit;
fi

# set the $coin_name variable to all lower case.
coin_name=${coin_name,,}
# set the secondary json search without the word coin in it. 
coin_no_coin=$coin_name
coin_no_coin=${coin_name//coin/}

# Save the global options in $STORAGE_ROOT/yiimp/.yiimp.conf so that standalone
# tools know where to look for data.
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'
PRIMARY_HOSTNAME='"${Domain_Name}"'

Using_Domain='"${Using_Domain}"'
Using_Sub_Domain='"${Using_Sub_Domain}"'
Domain_Name='"${Domain_Name}"'
Stratum_URL='"${Stratum_URL}"'
Install_SSL='"${Install_SSL}"'
Support_Email='"${Support_Email}"'
Admin_Pass='"'"''"${Admin_Pass}"''"'"'

coin_name='"'"''"${coin_name}"''"'"'
coin_symbol='"'"''"${coin_symbol}"''"'"'
coin_no_coin='"'"''"${coin_no_coin}"''"'"'

# Unless you do some serious modifications this installer will not work with any other repo of nomp!
YiiMPRepo='https://github.com/MorGn/cryptopool.builders-nomp-pool.git'
' | sudo -E tee $STORAGE_ROOT/nomp/.nomp.conf >/dev/null 2>&1

cd $HOME/multipool/nomp
