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
 

# set up data directory
#########################

echo_log "[info] Creating data directories..."
mkdir -p /data/incomplete
mkdir -p /data/downloads
mkdir -p /data/watch
chown -R nobody:users /data/incomplete /data/downloads /data/watch
chmod -R 777 /data/incomplete /data/downloads /data/watch

# set up openvpn
################

mkdir -p /config/openvpn

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
	
	if [[ ! -d "/config/privoxy" ]]; then
		mkdir /config/privoxy
		cp -R /etc/privoxy/* /config/privoxy/
	fi
	
	LAN_IP=$(hostname -i)
	sed -i -e "s/confdir \/etc\/privoxy/confdir \/config\/privoxy/g" /config/privoxy/config
	sed -i -e "s/logdir \/var\/log\/privoxy/logdir \/config\/privoxy/g" /config/privoxy/config
	sed -i -e "s/listen-address.*/listen-address  $LAN_IP:8118/g" /config/privoxy/config

	echo_log "[info] Privoxy configuration done"
fi

# set up nginx
##############
if [[ ! -d /config/nginx ]]; then
    mkdir /config/nginx
    if [[ ! -f /config/nginx/nginx.conf ]]; then
        cp /home/nobody/config/nginx/nginx.conf /config/nginx/
    fi
fi

# set up rtorrent
#################

if [[ ! -d /config/rtorrent ]]; then
    mkdir -p /config/rtorrent/session
    if [[ ! -f /config/rtorrent/rtorrent.rc ]]; then
        cp /home/nobody/config/rtorrent/rtorrent.rc /config/rtorrent/rtorrent.rc
    fi
fi

# set up rutorrent
##################

mkdir -p /srv/http/rutorrent/tmp

if [[ ! -d /config/rutorrent ]]; then
    rm -rf /config/rutorrent
    mkdir -p /config/rutorrent/conf
    cp -a /srv/http/rutorrent/conf.dist/* /config/rutorrent/conf/
    cp -af /home/nobody/config/rutorrent/config.php /config/rutorrent/conf/
fi
rm -rf /srv/http/rutorrent/conf
ln -sf /config/rutorrent/conf /srv/http/rutorrent/conf

# Select which plugins to enable
enabled_plugins=("_getdir" "_noty" "_noty2" "_task" "autotools" "check_port" "chunks" "cookies" "cpuload" "data" "datadir" "diskspace" "erasedata" "extsearch" "source" "tracklabels" "throttle" "trafic") 

mkdir -p /srv/http/rutorrent/conf/
for i in $(ls -1 /srv/http/rutorrent/plugins) ; do 
    if [[ " ${enabled_plugins[@]} " =~ " ${i} " ]]; then
       echo -e "\n[$(basename ${i})]\nenabled=yes" >> /srv/http/rutorrent/conf/plugins.ini
    else
       echo -e "\n[$(basename ${i})]\nenabled=no" >> /srv/http/rutorrent/conf/plugins.ini
    fi
done

# set up autotools
if [[ ! -f /srv/http/rutorrent/share/settings/autotools.dat ]]; then
    cp -af /home/nobody/config/rutorrent/autotools.dat /srv/http/rutorrent/share/settings/
fi
# Set autolools watch interval to 10s
sed -i -e "s/\$autowatch_interval =.*/\$autowatch_interval = 10;/g" /srv/http/rutorrent/plugins/autotools/conf.php

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
