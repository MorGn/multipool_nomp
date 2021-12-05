#!/usr/bin/env bash

#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/nomp/.nomp.conf

sudo mkdir -p /var/www/${Domain_Name}/html

echo '#####################################################
# Source Generated by nginxconfig.io
# Updated by cryptopool.builders for crypto use...
#####################################################

# NGINX Simple DDoS Defense
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_conn conn_limit_per_ip 80;
limit_req zone=req_limit_per_ip burst=80 nodelay;
limit_req_zone $binary_remote_addr zone=req_limit_per_ip:40m rate=5r/s;

server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	server_name www.'"${Domain_Name}"';
	set $base "/var/www/'"${Domain_Name}"'/html";
	root $base/web;

	# SSL
	ssl_certificate '"${STORAGE_ROOT}"'/ssl/ssl_certificate.pem;
	ssl_certificate_key '"${STORAGE_ROOT}"'/ssl/ssl_private_key.pem;

	# security
	include cryptopool.builders/security.conf;

	# logging
	access_log '"${STORAGE_ROOT}"'/nomp/logs/'"${Domain_Name}"'.app.access.log;
	error_log '"${STORAGE_ROOT}"'/nomp/logs/'"${Domain_Name}"'.app.error.log warn;

	# reverse proxy
	location / {
		proxy_pass http://127.0.0.1:3000;
		include cryptopool.builders/proxy.conf;
	}

	# additional config
	include cryptopool.builders/general.conf;
}

# HTTP redirect
server {
	listen 80;
	listen [::]:80;

	server_name .'"${Domain_Name}"';

	include cryptopool.builders/letsencrypt.conf;

	location / {
		return 301 https://'"${Domain_Name}"'$request_uri;
	}
}
' | sudo -E tee /etc/nginx/sites-available/${Domain_Name}.conf >/dev/null 2>&1

sudo ln -s /etc/nginx/sites-available/${Domain_Name}.conf /etc/nginx/sites-enabled/${Domain_Name}.conf
sudo ln -s $STORAGE_ROOT/nomp/site/web /var/www/${Domain_Name}/html

restart_service nginx
cd $HOME/multipool/nomp