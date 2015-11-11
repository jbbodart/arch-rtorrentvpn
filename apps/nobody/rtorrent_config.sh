#!/bin/bash
source /home/nobody/functions.sh

echo_log "[info] waiting for rtorrent to start up..."

# wait for rtorrent responding on the xmlrpc interface
until $(xmlrpc http://localhost:8080/RPC2 get_bind > /dev/null 2>&1); do
	sleep 1
done

echo_log "[info] rtorrent started, starting configuration"

if [[ "${RTORRENT_LISTEN_PORT}" =~ ^-?[0-9]+$ ]]; then
	echo_log "[info] configuring rtorrent listen port..."
	# enable bind incoming port to specific port (disable random)
	xmlrpc http://localhost:8080/RPC2 set_port_random i/0
	# set incoming port
	xmlrpc http://localhost:8080/RPC2 set_port_range "${RTORRENT_LISTEN_PORT}-${RTORRENT_LISTEN_PORT}"
fi

if [[ "${RTORRENT_DHT_PORT}" =~ ^-?[0-9]+$ ]]; then
	echo_log "[info] configuring rtorrent dht port..."
	# set dht port
	xmlrpc http://localhost:8080/RPC2 set_dht_port "${RTORRENT_DHT_PORT}"
fi

echo_log "[info] rtorrent configuration completed"