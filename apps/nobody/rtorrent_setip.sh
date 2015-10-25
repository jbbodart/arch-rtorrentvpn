#!/bin/bash

echo "[info] Configuring rtorrent listen interface..."

# wait for rtorrent responding on the xmlrpc interface
until $(xmlrpc http://localhost:8080/RPC2 get_bind > /dev/null 2>&1); do
	sleep 1
done

while true ; do
	if [[ "${ENABLE_VPN}" == "yes" ]]; then
		# run script to check VPN is up
		source /home/nobody/checkvpn.sh

		# get current VPN IP
		LOCAL_IP=$(ip addr | awk '/inet/ && /tun0/{sub(/\/.*$/,"",$2); print $2}')
		# query rtorrent for current listening interface
		LISTEN_INTERFACE=$(xmlrpc http://localhost:8080/RPC2 get_bind | tail -1 | awk '{print $NF}' | tr -d \')
		
		# if current listen interface ip is different than VPN tunnel ip then re-configure rtorrent
		if [[ "${LISTEN_INTERFACE}" != "${LOCAL_IP}" ]]; then
			echo "[info] VPN IP changed. Re-configuring rtorrent..."
			# set listen interface to tunnel local ip
			xmlrpc http://localhost:8080/RPC2 set_bind "${LOCAL_IP}"
			if [ $? -eq 0 ]; then
				echo "[info] Successfully bound rtorrent to ${LOCAL_IP}"
			fi
		fi
#	else
#		echo "[info] VPN disabled. Setting rtorrent to listen on any interface..."
#		xmlrpc http://localhost:8080/RPC2 set_bind "0.0.0.0"
#		if [ $? -eq 0 ]; then
#			echo "[info] Successfully bound rtorrent to 0.0.0.0"
#		fi
	fi
	sleep 1m
done






