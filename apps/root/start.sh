#!/bin/bash
source /home/nobody/functions.sh

# exit script if return code != 0
set -e

# set up variables
##################

if [[ ! -z "${RTORRENT_LISTEN_PORT}" ]]; then
    RTORRENT_LISTEN_PORT=49314
fi

if [[ ! -z "${RTORRENT_DHT_PORT}" ]]; then
    RTORRENT_LISTEN_PORT=49313
fi

# set up config directory
#########################

echo_log "[info] Creating config directories..."
 
mkdir -p /config/openvpn
mkdir -p /config/privoxy
mkdir -p /config/nginx
mkdir -p /config/rtorrent/session
mkdir -p /config/rutorrent
mkdir -p /config/log

# set up data directory
#########################

echo_log "[info] Creating data directories..."
mkdir -p /data/incomplete
mkdir -p /data/downloads
mkdir -p /data/watch
chown -R nobody:users /data/incomplete /data/downloads /data/watch
chmod -R 777 /data/incomplete /data/downloads /data/watch

# system set up
###############

# set up DNS
# add in OpenNIC public nameservers
echo 'nameserver 192.71.249.83' > /etc/resolv.conf
echo 'nameserver 87.98.175.85' >> /etc/resolv.conf
echo 'nameserver 92.222.80.28' >> /etc/resolv.conf
echo 'nameserver 5.135.183.146' >> /etc/resolv.conf

# set up timezone
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime

# set up sshd
#############

if [[ "${ENABLE_SSHD}" == "yes" ]]; then

    echo_log "[info] Configuring OpenSSH sever..."
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh

    if [[ -f "/config/sshd/authorized_keys" ]]; then
        cp -R /config/sshd/authorized_keys /root/.ssh/ && chmod 600 /root/.ssh/*
    fi

    LAN_IP=$(hostname -i)
    #sed -i -e "s/#ListenAddress.*/ListenAddress $LAN_IP/g" /etc/ssh/sshd_config
    sed -i -e "s/#Port 22/Port 2222/g" /etc/ssh/sshd_config
    sed -i -e "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
    sed -i -e "s/#PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
    sed -i -e "s/#PermitEmptyPasswords.*/PermitEmptyPasswords yes/g" /etc/ssh/sshd_config
    sed -i -e "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config

    echo_log "[info] OpenSSH server configuration done"
fi

# set up openvpn
################

if [[ "${ENABLE_VPN}" == "yes" ]]; then
    echo_log "[info] Configuring OpenVPN client..."
    # wildcard search for openvpn config files
    VPN_CONFIG=$(find /config/openvpn -maxdepth 1 -name "*.ovpn" -print)
        
    if [[ -z "${VPN_CONFIG}" ]]; then
	    echo_log "[crit] Missing OpenVPN configuration file in /config/openvpn/ (no files with an ovpn extension exist)"
	    echo_log "[crit] Please create and restart container"
	    exit 1
    fi
        
    # chek for kernel modules
    for i in "tun" "xt_mark" "iptable_mangle" ; do
        if [[ $(lsmod | awk -v module="$i" '$1==module {print $1}' | wc -l) -eq 0 ]] ; then
            echo_log "[crit] Missing $i kernel module. Please insmod and restart container"
            exit 1
        fi
    done
    
    # remove ping and ping-restart from ovpn file if present, now using flag --keepalive
    if $(grep -Fq "ping" "${VPN_CONFIG}"); then
	    sed -i '/ping.*/d' "${VPN_CONFIG}"
    fi

    # create the tunnel device
    [ -d /dev/net ] || mkdir -p /dev/net
    [ -c /dev/net/tun ] || mknod /dev/net/tun c 10 200

    # setup ip tables and routing for application
    source /root/iptables.sh

    echo_log "[info] OpenVPN configuration done"

fi

# set up privoxy
################

if [[ "${ENABLE_PRIVOXY}" == "yes" ]]; then	
	echo_log "[info] Configuring Privoxy"...

	if [[ ! -f "/config/privoxy/config" ]]; then
		cp -R /etc/privoxy/ /config/
	fi
		
	LAN_IP=$(hostname -i)
	sed -i -e "s/confdir \/etc\/privoxy/confdir \/config\/privoxy/g" /config/privoxy/config
	sed -i -e "s/logdir \/var\/log\/privoxy/logdir \/config\/privoxy/g" /config/privoxy/config
	sed -i -e "s/listen-address.*/listen-address  $LAN_IP:8118/g" /config/privoxy/config

	echo_log "[info] Privoxy configuration done"
fi

# set up nginx
##############
if [[ ! -f /config/nginx/nginx.conf ]]; then
    cp /home/nobody/config/nginx/nginx.conf /config/nginx/
fi

# set up php-fpm
################

sed -i -e "s/;daemonize =.*/daemonize = no/g" /etc/php/php-fpm.conf
sed -i -e "s/user = http/user = nobody/g" /etc/php/php-fpm.conf
sed -i -e "s/group = http/group = users/g" /etc/php/php-fpm.conf
sed -i -e "s/listen.owner = http/listen.owner = nobody/g" /etc/php/php-fpm.conf
sed -i -e "s/listen.group = http/listen.group = users/g" /etc/php/php-fpm.conf

#sed -i -e "s/open_basedir =.*/open_basedir = \/srv\/http\/:\/config\/rutorrent\//g" /etc/php/php.ini
sed -i -e "s/open_basedir =.*/; open_basedir = /g" /etc/php/php.ini

# set up rtorrent
#################

if [[ ! -f /config/rtorrent/rtorrent.rc ]]; then
    cp /home/nobody/config/rtorrent/rtorrent.rc /config/rtorrent/rtorrent.rc
fi

# set up rutorrent
##################

if [[ ! -f /config/rutorrent/conf/config.php ]]; then
    rm -rf /config/rutorrent/conf
    cp -a /srv/http/rutorrent/conf.dist /config/rutorrent/conf
    cp -af /home/nobody/config/rutorrent/config.php /config/rutorrent/conf/
    cp -af /home/nobody/config/rutorrent/autotools.dat /srv/http/rutorrent/share/settings/
    rm -f /srv/http/rutorrent/conf
    ln -sf /config/rutorrent/conf /srv/http/rutorrent/conf
fi

# Select which plugins to enable
enabled_plugins=("_getdir" "_noty" "_noty2" "_task" "autotools" "check_port" "chunks" "cookies" "cpuload" "data" "datadir" "diskspace" "erasedata" "extsearch" "geoip" "source" "tracklabels" "throttle" "trafic") 

for i in $(ls -1 /srv/http/rutorrent/plugins) ; do 
    if [[ " ${enabled_plugins[@]} " =~ " ${i} " ]]; then
	   echo -e "\n[$(basename ${i})]\nenabled=yes" >> /srv/http/rutorrent/conf/plugins.ini
    else
       echo -e "\n[$(basename ${i})]\nenabled=no" >> /srv/http/rutorrent/conf/plugins.ini
    fi
done

# Set autolools watch interval to 10s
sed -i -e "s/\$autowatch_interval =.*/\$autowatch_interval = 10;/g" /srv/http/rutorrent/plugins/autotools/conf.php

mkdir -p /srv/http/rutorrent/tmp

# set up permissions
####################

chown -R nobody:users /config/privoxy /config/rtorrent /config/rutorrent /srv/http/rutorrent/tmp
#chmod -R 775 /config/privoxy /config/deluge

# start everything
##################

if [[ "${ENABLE_SSHD}" == "yes" ]]; then
    echo_log "[info] Starting OpenSSH daemon..."
    supervisorctl start sshd
fi

if [[ "${ENABLE_VPN}" == "yes" ]]; then
    echo_log "[info] Starting OpenVPN..."
    supervisorctl start openvpn
fi

if [[ "${ENABLE_PRIVOXY}" == "yes" ]]; then
    echo_log "[info] Starting Privoxy..."
    supervisorctl start privoxy
fi

echo_log "[info] Starting rtorrent..."
supervisorctl start rtorrent

echo_log "[info] Configuring rtorrent..."
supervisorctl start rtorrent_config

if [[ "${ENABLE_VPN}" == "yes" ]]; then  
	echo_log "[info] Starting VPN IP monitoring..."
	supervisorctl start rtorrent_setip
fi

echo_log "[info] Starting php-fpm..."
supervisorctl start php-fpm

echo_log "[info] Starting nginx..."
supervisorctl start nginx
