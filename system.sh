#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

clear
source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/nomp/.nomp.conf

echo -e " Begin base system setup...$COL_RESET"
cd $HOME/multipool/nomp

# Set timezone
echo -e " Setting TimeZone to UTC...$COL_RESET"
if [ ! -f /etc/timezone ]; then
echo "Setting timezone to UTC."
echo "Etc/UTC" > sudo /etc/timezone
restart_service rsyslog
fi
echo -e "$GREEN Done...$COL_RESET"

# Add repository
echo -e " Adding the required repsoitories...$COL_RESET"
if [ ! -f /usr/bin/add-apt-repository ]; then
echo "Installing add-apt-repository..."
hide_output sudo apt-get -y update
apt_install software-properties-common
fi
echo -e "$GREEN Done...$COL_RESET"

# Upgrade System Files
echo -e " Updating system packages...$COL_RESET"
hide_output sudo apt-get update
echo -e " Upgrading system packages...$COL_RESET"
if [ ! -f /boot/grub/menu.lst ]; then
apt_get_quiet upgrade
else
sudo rm /boot/grub/menu.lst
hide_output sudo update-grub-legacy-ec2 -y
apt_get_quiet upgrade
fi
echo -e "$GREEN Done...$COL_RESET"

echo -e " Running Dist-Upgrade...$COL_RESET"
apt_get_quiet dist-upgrade
echo -e "$GREEN Done...$COL_RESET"

echo -e " Running Autoremove...$COL_RESET"
apt_get_quiet autoremove
echo -e "$GREEN Done...$COL_RESET"

echo -e " Installing Base system packages...$COL_RESET"
apt_install python3 python3-dev python3-pip \
wget curl git sudo coreutils bc \
haveged pollinate unzip \
unattended-upgrades cron ntp fail2ban screen
echo -e "$GREEN Done...$COL_RESET"

# ### Seed /dev/urandom
echo -e " Initializing system random number generator...$COL_RESET"
hide_output dd if=/dev/random of=/dev/urandom bs=1 count=32 2> /dev/null
hide_output sudo pollinate -q -r
echo -e "$GREEN Done...$COL_RESET"

echo -e " Initializing UFW Firewall...$COL_RESET"
if [ -z "${DISABLE_FIREWALL:-}" ]; then
	# Install `ufw` which provides a simple firewall configuration.
	apt_install ufw

	# Allow incoming connections to SSH.
	ufw_allow ssh;
	ufw_allow http;
	ufw_allow https;
	# ssh might be running on an alternate port. Use sshd -T to dump sshd's #NODOC
	# settings, find the port it is supposedly running on, and open that port #NODOC
	# too. #NODOC
	SSH_PORT=$(sshd -T 2>/dev/null | grep "^port " | sed "s/port //") #NODOC
	if [ ! -z "$SSH_PORT" ]; then
	if [ "$SSH_PORT" != "22" ]; then

	echo Opening alternate SSH port $SSH_PORT. #NODOC
	ufw_allow $SSH_PORT;
	ufw_allow http;
	ufw_allow https;

	fi
	fi

sudo ufw --force enable;
fi #NODOC
echo -e "$GREEN Done...$COL_RESET"

echo -e " Installing NOMP Required system packages...$COL_RESET"
if [ -f /usr/sbin/apache2 ]; then
	echo -e " $COL_RESET"
	echo -e " Removing apache...$COL_RESET"
hide_output apt-get -y purge apache2 apache2-*
hide_output apt-get -y --purge autoremove
echo -e "$GREEN Done...$COL_RESET"
fi
hide_output sudo apt-get update
apt_install nginx build-essential libtool autotools-dev \
autoconf pkg-config libssl-dev libboost-all-dev git \
libminiupnpc-dev libgmp3-dev libboost-dev libboost-system-dev libsodium-dev
echo -e "$GREEN Done...$COL_RESET"

echo -e " Installing Node 12.x$COL_RESET"
cd $STORAGE_ROOT/nomp/nomp_setup/tmp
curl -ss -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.1/install.sh | bash >/dev/null 2>&1
cd
. ~/.nvm/nvm.sh
. ~/.profile
. ~/.bashrc
nvm install 12.0.0 >/dev/null 2>&1
nvm use 12.0.0 >/dev/null 2>&1
apt_install npm
echo -e "$GREEN Done...$COL_RESET"

echo -e " Downloading cryptopool.builders NOMP Repo...$COL_RESET"
hide_output sudo git clone ${YiiMPRepo} $STORAGE_ROOT/nomp/nomp_setup/nomp
echo -e "$GREEN Done...$COL_RESET"

echo -e "$GREEN Base system installed...$COL_RESET"
cd $HOME/multipool/nomp
