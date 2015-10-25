#!/bin/bash

VPN_CONFIG=$(find /config/openvpn -maxdepth 1 -name "*.ovpn" -print)
/usr/bin/openvpn --cd /config/openvpn --config "${VPN_CONFIG}" --mute-replay-warnings --up /root/update-resolv-conf.sh --down /root/update-resolv-conf.sh --script-security 2 --keepalive 10 60
