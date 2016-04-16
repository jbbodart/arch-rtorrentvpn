#!/bin/bash

# exit script if return code != 0
set -e

# set up timezone
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime

# set up DNS
# add in OpenNIC public nameservers
echo 'nameserver 192.71.249.83' > /etc/resolv.conf
echo 'nameserver 87.98.175.85' >> /etc/resolv.conf
echo 'nameserver 92.222.80.28' >> /etc/resolv.conf
echo 'nameserver 5.135.183.146' >> /etc/resolv.conf

# define pacman packages
pacman_packages="net-tools openresolv curl unzip openssh nginx php php-fpm openvpn privoxy rtorrent"

# update packages
pacman -Syu --ignore filesystem --noconfirm

# install pre-reqs
#pacman -Sy --noconfirm
pacman -S --needed $pacman_packages --noconfirm

# set permissions
chown -R nobody:users /home/nobody /etc/privoxy
#chmod -R 775 /home/nobody /etc/privoxy 

# set up openssh
################

mkdir /var/run/sshd
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown -Rf root:root /root/.ssh
# generate host keys
/usr/bin/ssh-keygen -A
# set up sshd
sed -i -e "s/#Port 22/Port 2222/g" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i -e "s/#PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i -e "s/#PermitEmptyPasswords.*/PermitEmptyPasswords yes/g" /etc/ssh/sshd_config
sed -i -e "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config

# download and extract rutorrent 3.7
####################################

curl -L -O https://bintray.com/artifact/download/novik65/generic/ruTorrent-3.7.zip
unzip -q ruTorrent-3.7.zip
mv ruTorrent-master /srv/http/rutorrent
# for rutorrent tmp dir
mkdir -p /srv/http/rutorrent/tmp
chown -Rf nobody:users /srv/http/rutorrent
# backup original conf dir
mv /srv/http/rutorrent/conf /srv/http/rutorrent/conf.dist
rm -f ruTorrent-3.7.zip

# set up php-fpm
################

sed -i -e "s/;daemonize =.*/daemonize = no/g" /etc/php/php-fpm.conf
sed -i -e "s/user = http/user = nobody/g" /etc/php/php-fpm.d/www.conf
sed -i -e "s/group = http/group = users/g" //etc/php/php-fpm.d/www.conf
sed -i -e "s/listen.owner = http/listen.owner = nobody/g" /etc/php/php-fpm.d/www.conf
sed -i -e "s/listen.group = http/listen.group = users/g" /etc/php/php-fpm.d/www.conf
sed -i -e "s/open_basedir =.*/; open_basedir = /g" /etc/php/php.ini

# cleanup
#########
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /tmp/*
