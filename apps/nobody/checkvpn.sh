#!/bin/bash

# create function to check tunnel local ip is valid and interface is up
check_valid_ip() {
	IP_ADDRESS="$1"
	# check if ip address looks valid
	if [[ ! $IP_ADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		 return 1
	fi
	
	ip link | grep tun0 | grep -Eq 'UP'
	# check that interface is up
	if [[ ! $? ]]; then
		return 1
	fi
	return 0
}

# loop and wait until adapter tun0 local ip is valid
LOCAL_IP=$(ip addr | awk '/inet/ && /tun0/{sub(/\/.*$/,"",$2); print $2}')
while ! check_valid_ip "$LOCAL_IP"
do
	echo "[info] Waiting for a valid VPN tunnel..."
	sleep 5
	LOCAL_IP=$(ip addr | awk '/inet/ && /tun0/{sub(/\/.*$/,"",$2); print $2}')
done
