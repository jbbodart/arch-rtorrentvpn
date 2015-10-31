#!/bin/bash

# exit script if return code != 0
set -e

# define pacman packages
pacman_packages="net-tools openresolv curl unzip openvpn privoxy openssh nginx php php-fpm rtorrent mediainfo ffmpeg unrar"

# update packages
pacman -Syu --ignore filesystem --noconfirm

# install pre-reqs
#pacman -Sy --noconfirm
pacman -S --needed $pacman_packages --noconfirm

# set permissions
chown -R nobody:users /home/nobody /etc/privoxy
#chmod -R 775 /home/nobody /etc/privoxy 

# set up openssh
mkdir /var/run/sshd
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown -Rf root:root /root/.ssh
# generate host keys
/usr/bin/ssh-keygen -A

# download and extract rutorrent
#curl -L -O http://dl.bintray.com/novik65/generic/rutorrent-3.6.tar.gz
#curl -L -O http://dl.bintray.com/novik65/generic/plugins-3.6.tar.gz
#mkdir -p /srv/http/plugins
#tar -C /srv/http --strip-components=1 -zxvf rutorrent-3.6.tar.gz
#tar -C /srv/http -zxvf plugins-3.6.tar.gz
#rm -f rutorrent-3.6.tar.gz plugins-3.6.tar.gz

# download and extract rutorrent 3.7
curl -L -O https://bintray.com/artifact/download/novik65/generic/ruTorrent-3.7.zip
unzip -q ruTorrent-3.7.zip
mv ruTorrent-master /srv/http/rutorrent
# for rutorrent tmp dir
mkdir -p /srv/http/rutorrent/tmp
chown -Rf nobody:users /srv/http/rutorrent
# backup original conf dir
mv /srv/http/rutorrent/conf /srv/http/rutorrent/conf.dist
rm -f ruTorrent-3.7.zip

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /tmp/*
