#!/bin/bash

# ---------- Init variables ----------
project_path="path/to/project"
mysql_root_user="root"
mysql_root_password="root_password"
db_name="db_name"
db_user="db_user"
db_password="db_password"
old_db_name="old_db_name"
old_db_user="old_db_user"
old_db_password="old_db_password"
project_zip_path="path/to/project.zip"
domain="domain.com"
nginx_path="/etc/nginx/sites-available/domain.com"

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
sudo sed -i -e "s/post_max_size = 8M/post_max_size = 126M/g" /etc/php/7.4/fpm/php.ini
sudo sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 126M/g" /etc/php/7.4/fpm/php.ini
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

# ---------- Setup MySQL ----------
echo -e "\033[32m---------- START SETUP MYSQL ----------\033[0m"
mysql -u"$mysql_root_user" -p"$mysql_root_password" << EOF
CREATE USER '$db_user'@'localhost' IDENTIFIED WITH mysql_native_password BY '$db_password';
CREATE DATABASE $db_name;
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
echo -e "\033[32m---------- END SETUP MYSQL ----------\033[0m"

# ---------- Setup project ----------
echo -e "\033[32m---------- START SETUP PROJECT ----------\033[0m"

sudo unzip $project_zip_path
sudo chmod -R 755 $project_path
sudo chown -R www-data:www-data $project_path
sudo rm $project_zip_path

sed -i -e "s/$old_db_name/$db_name/g" $project_path/wp-config.php
sed -i -e "s/$old_db_user/$db_user/g" $project_path/wp-config.php
sed -i -e "s/$old_db_password/$db_password/g" $project_path/wp-config.php
echo -e "\033[32m---------- END SETUP PROJECT ----------\033[0m"

# ---------- Setup nginx ----------
echo -e "\033[32m---------- START SETUP NGINX ----------\033[0m"

sudo tee $nginx_path > /dev/null << EOM
server {
    listen 80;

    root $project_path;
    index index.php index.html index.htm;
    
    server_name $domain www.$domain;
        
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/12;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 2400:cb00::/32;
    set_real_ip_from 2606:4700::/32;
    set_real_ip_from 2803:f800::/32;
    set_real_ip_from 2405:b500::/32;
    set_real_ip_from 2405:8100::/32;
    set_real_ip_from 2c0f:f248::/32;
    set_real_ip_from 2a06:98c0::/29;
    real_ip_header CF-Connecting-IP;
    
    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    location = /favicon.ico {
        access_log off;
        log_not_found off;
        expires max;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|aac|m4a|mp3|ogg|ogv|webp)$ {
        expires 1M;
        access_log off;
        add_header Cache-Control "public";
    }

    location ~* \.(?:css(\.map)?|js(\.map)?)$ {
        add_header "Access-Control-Allow-Origin" "*";
        access_log off;
        log_not_found off;
        expires 30d;
    }

    location ~* \.(?:css|js)$ {
        expires 1y;
        access_log off;
        add_header Cache-Control "public";
    }
    
    client_max_body_size 126M;
}
EOM

sudo nginx -t
sudo ln -s $nginx_path /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default
sudo service nginx restart
echo -e "\033[32m---------- END SETUP NGINX ----------\033[0m"

echo -e "\033[32m========== DONE ==========\033[0m"
