#!/bin/bash

# get ip for local gateway (eth0)
DEFAULT_GATEWAY=$(ip route show default | awk '/default/ {print $3}')

# read port number and protocol from ovpn file (used to define iptables rule)

VPN_IP=$(/usr/bin/awk '$1=="remote"{print $2}' "${VPN_CONFIG}")
VPN_PORT=$(/usr/bin/awk '$1=="remote"{print $3}' "${VPN_CONFIG}")
VPN_PROTOCOL=$(/usr/bin/awk '$1=="proto"{print $2}' "${VPN_CONFIG}")

echo "[info] setting up routing table..."

# setup route for rutorrent/nginx using set-mark to route traffic for port 8080 to eth0
if ! grep "rutorrent" /etc/iproute2/rt_tables ; then
	echo "8080    rutorrent" >> /etc/iproute2/rt_tables
fi
ip rule add fwmark 1 table rutorrent
ip route add default via $DEFAULT_GATEWAY table rutorrent

# setup route for privoxy using set-mark to route traffic for port 8118 to eth0
if [[ $ENABLE_PRIVOXY == "yes" ]]; then
	if ! grep "privoxy" /etc/iproute2/rt_tables ; then
		echo "8118    privoxy" >> /etc/iproute2/rt_tables
	fi
	ip rule add fwmark 2 table privoxy
	ip route add default via $DEFAULT_GATEWAY table privoxy
fi

# setup route for sshd using set-mark to route traffic for port 2222 to eth0
if [[ $ENABLE_SSHD == "yes" ]]; then
	if ! grep "sshd" /etc/iproute2/rt_tables ; then
		echo "2222    sshd" >> /etc/iproute2/rt_tables
	fi
	ip rule add fwmark 3 table sshd
	ip route add default via $DEFAULT_GATEWAY table sshd
fi

echo "[info] Done. IP routing table :"
ip route show table all

echo "[info] Configuring iptables..."

# input iptable rules
#####################

# set default policy
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# VPN tunnel adapter
#iptables -A INPUT -i tun0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
#iptables -A INPUT -i tun0 -p tcp --dport ${RTORRENT_LISTEN_PORT} -j ACCEPT
#iptables -A INPUT -i tun0 -p udp --dport ${RTORRENT_DHT_PORT} -j ACCEPT
iptables -A INPUT -i tun0 -j ACCEPT
iptables -A OUTPUT -o tun0 -j ACCEPT

# accept input to/from docker containers (172.x range is internal dhcp)
iptables -A INPUT -s 172.17.0.0/16 -d 172.17.0.0/16 -j ACCEPT
iptables -A OUTPUT -s 172.17.0.0/16 -d 172.17.0.0/16 -j ACCEPT

# DHCP
#iptables -A OUTPUT -d 255.255.255.255 -j ACCEPT
#iptables -A INPUT -s 255.255.255.255 -j ACCEPT

# Local Network
if [[ ! -z "${LAN_RANGE}" ]]; then
	iptables -A INPUT -s ${LAN_RANGE} -d ${LAN_RANGE} -j ACCEPT
	iptables -A OUTPUT -s ${LAN_RANGE} -d ${LAN_RANGE} -j ACCEPT
fi

# VPN
iptables -A INPUT -i eth0 -s ${VPN_IP} -p ${VPN_PROTOCOL} --sport ${VPN_PORT} -j ACCEPT
iptables -A OUTPUT -o eth0 -d ${VPN_IP} -p ${VPN_PROTOCOL} --dport ${VPN_PORT} -j ACCEPT

# accept output from nginx port 8080
iptables -t mangle -A OUTPUT -p tcp --sport 8080 -j MARK --set-mark 1
iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 8080 -j ACCEPT

# accept input to privoxy port 8118 if enabled
if [[ $ENABLE_PRIVOXY == "yes" ]]; then
	iptables -t mangle -A OUTPUT -p tcp --sport 8118 -j MARK --set-mark 2
	iptables -A INPUT -i eth0 -p tcp --dport 8118 -j ACCEPT
	iptables -A OUTPUT -o eth0 -p tcp --sport 8118 -j ACCEPT
fi

# accept input to sshd port 2222 if enabled
if [[ $ENABLE_SSHD == "yes" ]]; then
	iptables -t mangle -A OUTPUT -p tcp --sport 2222 -j MARK --set-mark 3
	iptables -A INPUT -i eth0 -p tcp --dport 2222 -j ACCEPT
	iptables -A OUTPUT -o eth0 -p tcp --sport 2222 -j ACCEPT
fi

# accept output for dns lookup
#iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

echo "[info] Done. iptables rules :"
iptables -S
