#!/bin/bash
source /home/nobody/functions.sh

# Maximum percent packet loss before a restart
maxPloss=50

restart_openvpn() {
  echo_log "[info] Killing OpenVPN..."
  kill $(cat /var/run/openvpn.pid)
  sleep 1m
}

while true ; do

  # check DNS resolution	
	if ! $(host -W5 www.google.com > /dev/null 2>&1); then
    echo_log "[warn] DNS resolution failed"
    restart_openvpn
    continue
  fi

  ploss=101
  ploss=$(ping -q -w10 www.google.com | grep -o "[0-9]*%" | tr -d %) > /dev/null 2>&1
	if [ "$ploss" -gt "$maxPloss" ]; then
    echo_log "[warn] Packet loss ($ploss%) exceeded $maxPloss"
    restart_openvpn
	fi
	sleep 1m
done
