#!/bin/bash

set -e

echo "📦 Updating system..."
sudo pacman -Syu --noconfirm

echo "🌐 Installing required packages..."
sudo pacman -S --noconfirm php php-gd php-curl php-intl php-mysql php-pgsql php-sqlite php-xml php-zip php-bcmath php-mbstring php-cli php-apache \
    apache mariadb nodejs npm git unzip zip wget curl

echo "🪄 Enabling PHP modules..."
# No specific action needed unless using php.ini tweaks

echo "🐘 Setting up MySQL (MariaDB)..."
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo "🔐 Securing MySQL installation..."
sudo mysql_secure_installation

echo "🎼 Installing Composer..."
cd ~
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    echo '❌ ERROR: Invalid Composer installer signature'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
sudo mv composer.phar /usr/local/bin/composer
rm composer-setup.php

echo "📦 Installing Laravel installer globally..."
composer global require laravel/installer

echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "✅ All done!"
echo "📁 To create a new Laravel project, run:"
echo "laravel new project-name"
