#!/bin/bash
source /home/nobody/functions.sh

echo_log "[info] Configuring iptables..."

# read port number and protocol from ovpn file (used to define iptables rule)
VPN_IP=$(/usr/bin/awk '$1=="remote"{print $2}' "${VPN_CONFIG}")
VPN_PORT=$(/usr/bin/awk '$1=="remote"{print $3}' "${VPN_CONFIG}")
VPN_PROTOCOL=$(/usr/bin/awk '$1=="proto"{print $2}' "${VPN_CONFIG}")

# input iptable rules
#####################

# set default policy
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# allow already established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# VPN tunnel adapter
iptables -A INPUT -i tun0 -p tcp --dport ${RTORRENT_LISTEN_PORT} -j ACCEPT
iptables -A INPUT -i tun0 -p udp --dport ${RTORRENT_DHT_PORT} -j ACCEPT
iptables -A OUTPUT -o tun0 -j ACCEPT

# Network adapter
# VPN
iptables -A INPUT -i eth0 -s ${VPN_IP} -p ${VPN_PROTOCOL} --sport ${VPN_PORT} -j ACCEPT
iptables -A OUTPUT -o eth0 -d ${VPN_IP} -p ${VPN_PROTOCOL} --dport ${VPN_PORT} -j ACCEPT
# rutorrent/nginx
iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 8080 -j ACCEPT
# privoxy if enabled
if [[ $ENABLE_PRIVOXY == "yes" ]]; then
	iptables -A INPUT -i eth0 -p tcp --dport 8118 -j ACCEPT
	iptables -A OUTPUT -o eth0 -p tcp --sport 8118 -j ACCEPT
fi

# Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

echo_log "[info] Done. iptables rules :"
iptables -S
