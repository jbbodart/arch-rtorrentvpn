#!/bin/bash
source /home/nobody/functions.sh

echo_log "[info] starting rtorrent..."

if [[ $VPN_ENABLED == "yes" ]]; then
	echo_log "[info] VPN enabled, waiting for tun0 interface to come up..."
	# run script to check ip is valid for tun0
	source /home/nobody/checkvpn.sh
fi

# remove lock files
rm -f /config/rtorrent/session/rtorrent.lock
rm -f /config/rtorrent/session/rtorrent_scgi.socket

echo_log "[info] All checks complete, starting rtorrent..."

# run rtorrent
/usr/bin/rtorrent -n -o import=/config/rtorrent/rtorrent.rc > /dev/null
