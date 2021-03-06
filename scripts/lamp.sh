#!/bin/bash

if [ -z "$PS1" ]; then
	set -euo pipefail
	unalias -a
fi

# mysql
yum install -y mariadb-server mariadb
cp /vagrant/configs/mysql/mysql.server.cnf /etc/my.cnf
systemctl enable mariadb
systemctl start mariadb

# equivalent to mysql_secure_installation
mysql --no-defaults <<ENDSQL
UPDATE mysql.user SET password=PASSWORD('root') WHERE user='root';
DELETE FROM mysql.user WHERE user='';
DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE test;
DELETE FROM mysql.db WHERE db='test' OR db LIKE 'test_%';
FLUSH PRIVILEGES;
ENDSQL

# apache2
yum install -y httpd httpd-tools
cp /vagrant/configs/httpd/httpd.ports.conf /etc/httpd/conf.d/ports.conf
systemctl enable httpd.service
systemctl start httpd.service

# php 5.4? No thank you.
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php56

yum install -y ImageMagick php php-xml php-fpm php-gd \
  php-mbstring php-mysqlnd php-opcache php-pecl-imagick \
  php-pecl-mysql php-pecl-zip php-soap

yum install -y php-posix --enablerepo=remi
sed -i -e 's/;date.timezone =/date.timezone = America\/Vancouver/' /etc/php.ini

systemctl enable php-fpm.service
systemctl start php-fpm.service
systemctl restart httpd.service

curl -Ss https://getcomposer.org/installer | php -- --version=1.10.20 --quiet --install-dir=/usr/local/bin --filename=composer

echo "<?php phpinfo(); ?>" > /var/www/html/info.php
