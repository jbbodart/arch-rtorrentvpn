#!/bin/bash

echo "[info] starting rtorrent..."

if [[ $VPN_ENABLED == "yes" ]]; then
	echo "[info] VPN enabled, waiting for tun0 interface to come up..."
	# run script to check ip is valid for tun0
	source /home/nobody/checkvpn.sh
fi

echo "[info] All checks complete, starting rtorrent..."

# run rtorrent
/usr/bin/rtorrent -n -o import=/config/rtorrent/rtorrent.rc > /dev/null
