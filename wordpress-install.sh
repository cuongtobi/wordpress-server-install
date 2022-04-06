#!/bin/bash

# ---------- Init variables ----------
mysql_root_password="test@123WP"

# ---------- Enable firewall ----------
echo -e "\033[32m---------- START ENABLE FIREWALL ----------\033[0m"
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 25/tcp
sudo ufw --force enable
echo -e "\033[32m---------- END ENABLE FIREWALL ----------\033[0m"

# ---------- Add swap ----------
echo -e "\033[32m---------- START ADD SWAP ----------\033[0m"
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
echo -e "\033[32m---------- END ADD SWAP ----------\033[0m"

# ---------- Install nginx ----------
echo -e "\033[32m---------- START INSTALL NGINX ----------\033[0m"
sudo apt-get install nginx -y
echo -e "\033[32m---------- END INSTALL NGINX ----------\033[0m"

# ---------- Install zip and unzip ----------
echo -e "\033[32m---------- START INSTALL ZIP AND UNZIP ----------\033[0m"
sudo apt-get install zip unzip -y
echo -e "\033[32m---------- END INSTALL ZIP AND UNZIP ----------\033[0m"

# ---------- Install php 7.4 ----------
echo -e "\033[32m---------- START INSTALL PHP 7.4 ----------\033[0m"
sudo apt-get install software-properties-common python-software-properties -y
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update
sudo apt-get install php7.4 php7.4-cli php7.4-common php7.4-fpm -y
sudo apt-get install php7.4-curl php7.4-gd php7.4-json php7.4-mbstring php7.4-intl php7.4-mysql php7.4-xml php7.4-zip php7.4-bcmath -y

sudo sed -i -e "s/memory_limit = 128M/memory_limit = 800M/g" /etc/php/7.4/fpm/php.ini
sudo sed -i -e "s/post_max_size = 8M/post_max_size = 125M/g" /etc/php/7.4/fpm/php.ini
sudo sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 125M/g" /etc/php/7.4/fpm/php.ini
sudo service php7.4-fpm restart
echo -e "\033[32m---------- END INSTALL PHP 7.4 ----------\033[0m"

# ---------- Install mysql-server ----------
echo -e "\033[32m---------- START INSTALL MYSQL SERVER ----------\033[0m"
sudo apt-get install mysql-server -y
sudo mysql << EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$mysql_root_password';
FLUSH PRIVILEGES;
EOF
echo -e "\033[32m---------- END INSTALL MYSQL SERVER ----------\033[0m"
